require "rails_helper"

RSpec.describe Library::SendReminderJob do
  let(:reader) { create(:reader, full_name: "Alice Smith", email: "alice@example.com") }
  let(:book) { create(:book, title: "Ruby Programming", serial_number: "654321") }

  describe "#perform" do
    context "when borrowing a book and time advances to reminder dates" do
      it "sends 3-day warning email when job fires 3 days before due date" do
        borrow_date = Date.new(2026, 3, 1)

        borrow = travel_to(borrow_date) do
          create(:book_borrow, book: book, reader: reader, borrow_date: borrow_date, due_date: borrow_date + 30.days)
        end

        reminder = create(:reminder, book_borrow: borrow, reminder_type: "3_days_warning", scheduled_for: borrow.due_date - 3.days)

        travel_to(borrow.due_date - 3.days) do
          expect {
            described_class.perform_now(reminder.id)
          }.to change { ActionMailer::Base.deliveries.count }.by(1)

          email = ActionMailer::Base.deliveries.last
          expect(email.to).to eq(["alice@example.com"])
          expect(email.subject).to include("due in 3 days")
          expect(email.body.encoded).to include("Ruby Programming")
          expect(email.body.encoded).to include("654321")
        end
      end

      it "sends due date alert email when job fires on the due date" do
        borrow_date = Date.new(2026, 3, 1)

        borrow = travel_to(borrow_date) do
          create(:book_borrow, book: book, reader: reader, borrow_date: borrow_date, due_date: borrow_date + 30.days)
        end

        reminder = create(:reminder, :due_date_alert, book_borrow: borrow, scheduled_for: borrow.due_date)

        travel_to(borrow.due_date) do
          expect {
            described_class.perform_now(reminder.id)
          }.to change { ActionMailer::Base.deliveries.count }.by(1)

          email = ActionMailer::Base.deliveries.last
          expect(email.to).to eq(["alice@example.com"])
          expect(email.subject).to include("due today")
          expect(email.body.encoded).to include("Ruby Programming")
          expect(email.body.encoded).to include("654321")
        end
      end

      it "does not send email if book was returned before reminder fires" do
        borrow_date = Date.new(2026, 3, 1)

        borrow = travel_to(borrow_date) do
          create(:book_borrow, book: book, reader: reader, borrow_date: borrow_date, due_date: borrow_date + 30.days)
        end

        reminder = create(:reminder, book_borrow: borrow, reminder_type: "3_days_warning", scheduled_for: borrow.due_date - 3.days)

        # Return the book before the reminder fires
        travel_to(borrow_date + 10.days) do
          borrow.update!(return_date: Date.current)
        end

        travel_to(borrow.due_date - 3.days) do
          expect {
            described_class.perform_now(reminder.id)
          }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end

      it "does not send email twice if job runs again" do
        borrow_date = Date.new(2026, 3, 1)

        borrow = travel_to(borrow_date) do
          create(:book_borrow, book: book, reader: reader, borrow_date: borrow_date, due_date: borrow_date + 30.days)
        end

        reminder = create(:reminder, book_borrow: borrow, reminder_type: "3_days_warning", scheduled_for: borrow.due_date - 3.days)

        travel_to(borrow.due_date - 3.days) do
          described_class.perform_now(reminder.id)

          expect {
            described_class.perform_now(reminder.id)
          }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end
  end

  describe "job scheduling via BorrowBook" do
    it "enqueues two SendReminderJobs when a book is borrowed" do
      travel_to(Date.new(2026, 3, 1)) do
        expect {
          Library::BorrowBook.new(book_id: book.id, reader_id: reader.id).execute
        }.to have_enqueued_job(Library::SendReminderJob).exactly(2).times
      end
    end

    it "creates two reminder records when a book is borrowed" do
      travel_to(Date.new(2026, 3, 1)) do
        expect {
          Library::BorrowBook.new(book_id: book.id, reader_id: reader.id).execute
        }.to change(Reminder, :count).by(2)
      end
    end

    it "schedules a 3_days_warning reminder for 3 days before due date" do
      travel_to(Date.new(2026, 3, 1)) do
        Library::BorrowBook.new(book_id: book.id, reader_id: reader.id).execute

        borrow = BookBorrow.last
        warning = Reminder.find_by(book_borrow: borrow, reminder_type: "3_days_warning")

        expect(warning).to be_present
        expect(warning.scheduled_for).to eq(borrow.due_date - 3.days)
        expect(warning.sent_at).to be_nil
      end
    end

    it "schedules a due_date_alert reminder for the due date" do
      travel_to(Date.new(2026, 3, 1)) do
        Library::BorrowBook.new(book_id: book.id, reader_id: reader.id).execute

        borrow = BookBorrow.last
        alert = Reminder.find_by(book_borrow: borrow, reminder_type: "due_date_alert")

        expect(alert).to be_present
        expect(alert.scheduled_for).to eq(borrow.due_date)
        expect(alert.sent_at).to be_nil
      end
    end

    it "does not schedule reminders when borrow fails" do
      expect {
        Library::BorrowBook.new(book_id: nil, reader_id: reader.id).execute
      }.not_to change(Reminder, :count)
    end
  end
end
