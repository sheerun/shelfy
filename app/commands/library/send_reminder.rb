module Library
  class SendReminder < LibraryCommand
    attr_accessor :reminder_id

    validates :reminder_id, presence: true

    private

    def run
      return validation_failure unless valid?

      Reminder.transaction do
        reminder = Reminder.lock.find(reminder_id)

        return already_sent_result if reminder.sent_at.present?
        return already_returned_result if reminder.book_borrow.return_date.present?

        ReminderMailer.with(reminder: reminder).reminder_email.deliver_now

        reminder.update!(sent_at: Time.current)
      end

      Library::Result.new(status: :ok)
    end

    def already_sent_result
      Library::Result.new(status: :ok)
    end

    def already_returned_result
      Library::Result.new(status: :ok)
    end

    def validation_failure
      Library::Result.new(status: :unprocessable, errors: errors.to_hash)
    end
  end
end
