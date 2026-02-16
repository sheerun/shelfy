class ReminderMailer < ApplicationMailer
  def reminder_email
    @reminder = params[:reminder]
    @book_borrow = @reminder.book_borrow
    @book = @book_borrow.book
    @reader = @book_borrow.reader
    @due_date = @book_borrow.due_date

    mail(
      to: @reader.email,
      subject: subject_for(@reminder.reminder_type)
    )
  end

  private

  def subject_for(reminder_type)
    case reminder_type
    when "3_days_warning"
      "Reminder: \"#{@book.title}\" is due in 3 days"
    when "due_date_alert"
      "Action Required: \"#{@book.title}\" is due today"
    end
  end
end
