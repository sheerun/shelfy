module Library
  class BorrowBook < LibraryCommand
    attr_accessor :book_id, :reader_id

    validates :book_id, presence: true
    validates :reader_id, presence: true

    private

    def run
      return validation_failure unless valid?

      book = Book.find(book_id)
      Reader.find(reader_id)

      if book.active_borrow.present?
        return Library::Result.new(
          status: :unprocessable,
          errors: {base: "Book is already borrowed"}
        )
      end

      today = Date.current
      borrow = BookBorrow.create!(
        book_id: book_id,
        reader_id: reader_id,
        borrow_date: today,
        due_date: today + BookBorrow::LOAN_PERIOD_DAYS.days
      )

      schedule_reminders(borrow)

      borrow_with_reader = BookBorrow.with_reader.find(borrow.id)

      Library::Result.new(
        data: Library::BookBorrowBlueprint.render_as_hash(borrow_with_reader),
        status: :created
      )
    end

    def validation_failure
      Library::Result.new(status: :unprocessable, errors: errors.to_hash)
    end

    def schedule_reminders(borrow)
      warning_date = borrow.due_date - 3.days
      warning_reminder = borrow.reminders.create!(
        reminder_type: "3_days_warning",
        scheduled_for: warning_date
      )
      Library::SendReminderJob.set(wait_until: warning_date.beginning_of_day).perform_later(warning_reminder.id)

      due_reminder = borrow.reminders.create!(
        reminder_type: "due_date_alert",
        scheduled_for: borrow.due_date
      )
      Library::SendReminderJob.set(wait_until: borrow.due_date.beginning_of_day).perform_later(due_reminder.id)
    end
  end
end
