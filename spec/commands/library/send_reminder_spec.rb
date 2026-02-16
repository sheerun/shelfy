require "rails_helper"

RSpec.describe Library::SendReminder do
  describe "#execute" do
    let(:reader) { create(:reader, full_name: "Jane Doe", email: "jane@example.com") }
    let(:book) { create(:book, title: "The Great Gatsby", serial_number: "123456") }
    let(:book_borrow) { create(:book_borrow, book: book, reader: reader, due_date: Date.new(2026, 3, 18)) }

    context "with a 3_days_warning reminder" do
      let(:reminder) { create(:reminder, book_borrow: book_borrow, reminder_type: "3_days_warning", scheduled_for: book_borrow.due_date - 3.days) }

      it "sends the reminder email" do
        expect {
          described_class.new(reminder_id: reminder.id).execute
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it "marks the reminder as sent" do
        freeze_time do
          described_class.new(reminder_id: reminder.id).execute
          expect(reminder.reload.sent_at).to eq(Time.current)
        end
      end

      it "sends email to the reader" do
        described_class.new(reminder_id: reminder.id).execute
        email = ActionMailer::Base.deliveries.last

        expect(email.to).to eq(["jane@example.com"])
      end

      it "includes book title in the email subject" do
        described_class.new(reminder_id: reminder.id).execute
        email = ActionMailer::Base.deliveries.last

        expect(email.subject).to eq('Reminder: "The Great Gatsby" is due in 3 days')
      end

      it "includes book title in the email body" do
        described_class.new(reminder_id: reminder.id).execute
        email = ActionMailer::Base.deliveries.last

        expect(email.body.encoded).to include("The Great Gatsby")
      end

      it "includes book serial number in the email body" do
        described_class.new(reminder_id: reminder.id).execute
        email = ActionMailer::Base.deliveries.last

        expect(email.body.encoded).to include("123456")
      end

      it "includes due date in the email body" do
        described_class.new(reminder_id: reminder.id).execute
        email = ActionMailer::Base.deliveries.last

        expect(email.body.encoded).to include("March 18, 2026")
      end

      it "includes reader name in the email body" do
        described_class.new(reminder_id: reminder.id).execute
        email = ActionMailer::Base.deliveries.last

        expect(email.body.encoded).to include("Jane Doe")
      end

      it "includes friendly warning wording" do
        described_class.new(reminder_id: reminder.id).execute
        email = ActionMailer::Base.deliveries.last

        expect(email.body.encoded).to include("friendly reminder")
        expect(email.body.encoded).to include("due for return in 3 days")
      end
    end

    context "with a due_date_alert reminder" do
      let(:reminder) { create(:reminder, :due_date_alert, book_borrow: book_borrow, scheduled_for: book_borrow.due_date) }

      it "sends the reminder email" do
        expect {
          described_class.new(reminder_id: reminder.id).execute
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it "includes urgent subject line" do
        described_class.new(reminder_id: reminder.id).execute
        email = ActionMailer::Base.deliveries.last

        expect(email.subject).to eq('Action Required: "The Great Gatsby" is due today')
      end

      it "includes urgent wording in body" do
        described_class.new(reminder_id: reminder.id).execute
        email = ActionMailer::Base.deliveries.last

        expect(email.body.encoded).to include("urgent reminder")
        expect(email.body.encoded).to include("due for return today")
      end

      it "includes book title and serial number in body" do
        described_class.new(reminder_id: reminder.id).execute
        email = ActionMailer::Base.deliveries.last

        expect(email.body.encoded).to include("The Great Gatsby")
        expect(email.body.encoded).to include("123456")
      end
    end

    context "when reminder was already sent" do
      let(:reminder) { create(:reminder, :sent, book_borrow: book_borrow) }

      it "does not send email again" do
        expect {
          described_class.new(reminder_id: reminder.id).execute
        }.not_to change { ActionMailer::Base.deliveries.count }
      end

      it "returns success" do
        result = described_class.new(reminder_id: reminder.id).execute
        expect(result).to be_success
      end
    end

    context "when book was already returned" do
      let(:book_borrow) { create(:book_borrow, :returned, book: book, reader: reader, due_date: Date.new(2026, 3, 18)) }
      let(:reminder) { create(:reminder, book_borrow: book_borrow) }

      it "does not send email" do
        expect {
          described_class.new(reminder_id: reminder.id).execute
        }.not_to change { ActionMailer::Base.deliveries.count }
      end

      it "does not mark reminder as sent" do
        described_class.new(reminder_id: reminder.id).execute
        expect(reminder.reload.sent_at).to be_nil
      end

      it "returns success" do
        result = described_class.new(reminder_id: reminder.id).execute
        expect(result).to be_success
      end
    end

    context "with missing reminder_id" do
      it "returns validation error" do
        result = described_class.new(reminder_id: nil).execute
        expect(result).to be_failure
        expect(result.errors[:reminder_id]).to be_present
      end
    end

    context "with non-existent reminder" do
      it "returns not_found" do
        result = described_class.new(reminder_id: "00000000-0000-0000-0000-000000000000").execute
        expect(result).to be_failure
        expect(result.status).to eq(:not_found)
      end
    end
  end
end
