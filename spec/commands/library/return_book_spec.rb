require "rails_helper"

RSpec.describe Library::ReturnBook do
  describe "#execute" do
    let(:book) { create(:book) }
    let(:reader) { create(:reader) }

    context "when book is currently borrowed" do
      let!(:borrow) { create(:book_borrow, book: book, reader: reader) }

      it "returns the borrow with return_date set" do
        result = described_class.new(book_id: book.id).execute

        expect(result).to be_success
        expect(result.data[:return_date]).to eq(Date.current)
        expect(result.data[:reader_card_number]).to eq(reader.serial_number)
        expect(result.data[:reader_email]).to eq(reader.email)
      end

      it "sets return_date to today" do
        described_class.new(book_id: book.id).execute

        expect(borrow.reload.return_date).to eq(Date.current)
      end

      it "allows the book to be borrowed again after return" do
        described_class.new(book_id: book.id).execute

        new_reader = create(:reader)
        result = Library::BorrowBook.new(book_id: book.id, reader_id: new_reader.id).execute
        expect(result).to be_success
      end
    end

    context "when book is not currently borrowed" do
      it "returns error" do
        result = described_class.new(book_id: book.id).execute

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable)
        expect(result.errors[:base]).to eq("Book is not currently borrowed")
      end
    end

    context "when book was borrowed and already returned" do
      before { create(:book_borrow, :returned, book: book, reader: reader) }

      it "returns error" do
        result = described_class.new(book_id: book.id).execute

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable)
        expect(result.errors[:base]).to eq("Book is not currently borrowed")
      end
    end

    context "with missing book_id" do
      it "returns validation error" do
        result = described_class.new(book_id: nil).execute

        expect(result).to be_failure
        expect(result.errors[:book_id]).to be_present
      end
    end

    context "with non-existent book" do
      it "returns not_found" do
        result = described_class.new(
          book_id: "00000000-0000-0000-0000-000000000000"
        ).execute

        expect(result).to be_failure
        expect(result.status).to eq(:not_found)
      end
    end
  end
end
