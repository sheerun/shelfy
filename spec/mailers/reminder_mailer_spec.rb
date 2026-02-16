require "rails_helper"

RSpec.describe ReminderMailer do
  describe "#reminder_email" do
    let(:reader) { create(:reader, full_name: "John Smith", email: "john@example.com") }
    let(:book) { create(:book, title: "Clean Code", serial_number: "789012", author: "Robert C. Martin") }
    let(:book_borrow) { create(:book_borrow, book: book, reader: reader, due_date: Date.new(2026, 4, 15)) }

    context "with 3_days_warning reminder" do
      let(:reminder) { create(:reminder, book_borrow: book_borrow, reminder_type: "3_days_warning", scheduled_for: book_borrow.due_date - 3.days) }
      let(:mail) { described_class.with(reminder: reminder).reminder_email }

      it "renders the correct subject" do
        expect(mail.subject).to eq('Reminder: "Clean Code" is due in 3 days')
      end

      it "sends to the reader email" do
        expect(mail.to).to eq(["john@example.com"])
      end

      it "includes the reader name in the body" do
        expect(mail.body.encoded).to include("John Smith")
      end

      it "includes the book title in the body" do
        expect(mail.body.encoded).to include("Clean Code")
      end

      it "includes the book serial number in the body" do
        expect(mail.body.encoded).to include("789012")
      end

      it "includes the due date in the body" do
        expect(mail.body.encoded).to include("April 15, 2026")
      end

      it "includes friendly warning tone" do
        expect(mail.body.encoded).to include("friendly reminder")
      end

      it "mentions the book is due in 3 days" do
        expect(mail.body.encoded).to include("due for return in 3 days")
      end

      it "renders both html and text parts" do
        expect(mail.body.parts.map(&:content_type)).to include(
          a_string_matching("text/html"),
          a_string_matching("text/plain")
        )
      end
    end

    context "with due_date_alert reminder" do
      let(:reminder) { create(:reminder, :due_date_alert, book_borrow: book_borrow, scheduled_for: book_borrow.due_date) }
      let(:mail) { described_class.with(reminder: reminder).reminder_email }

      it "renders the correct subject" do
        expect(mail.subject).to eq('Action Required: "Clean Code" is due today')
      end

      it "sends to the reader email" do
        expect(mail.to).to eq(["john@example.com"])
      end

      it "includes the reader name in the body" do
        expect(mail.body.encoded).to include("John Smith")
      end

      it "includes the book title in the body" do
        expect(mail.body.encoded).to include("Clean Code")
      end

      it "includes the book serial number in the body" do
        expect(mail.body.encoded).to include("789012")
      end

      it "includes the due date in the body" do
        expect(mail.body.encoded).to include("April 15, 2026")
      end

      it "includes urgent tone" do
        expect(mail.body.encoded).to include("urgent reminder")
      end

      it "mentions the book is due today" do
        expect(mail.body.encoded).to include("due for return today")
      end

      it "mentions returning immediately" do
        expect(mail.body.encoded).to include("return the book immediately")
      end
    end
  end
end
