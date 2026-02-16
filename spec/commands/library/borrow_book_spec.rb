require "rails_helper"

RSpec.describe Library::BorrowBook do
  describe "#execute" do
    let(:book) { create(:book) }
    let(:reader) { create(:reader) }

    context "with valid attributes" do
      it "creates a borrow record" do
        result = described_class.new(book_id: book.id, reader_id: reader.id).execute

        expect(result).to be_success
        expect(result.status).to eq(:created)
        expect(result.data[:borrow_date]).to eq(Date.current)
        expect(result.data[:due_date]).to eq(Date.current + 30.days)
        expect(result.data[:return_date]).to be_nil
        expect(result.data[:reader_card_number]).to eq(reader.serial_number)
        expect(result.data[:reader_email]).to eq(reader.email)
      end

      it "persists the borrow in the database" do
        expect {
          described_class.new(book_id: book.id, reader_id: reader.id).execute
        }.to change(BookBorrow, :count).by(1)
      end

      it "sets borrow_date to today" do
        described_class.new(book_id: book.id, reader_id: reader.id).execute

        borrow = BookBorrow.last
        expect(borrow.borrow_date).to eq(Date.current)
      end

      it "sets due_date to 30 days from today" do
        described_class.new(book_id: book.id, reader_id: reader.id).execute

        borrow = BookBorrow.last
        expect(borrow.due_date).to eq(Date.current + 30.days)
      end
    end

    context "when book is already borrowed" do
      before { create(:book_borrow, book: book, reader: reader) }

      it "returns error" do
        other_reader = create(:reader)
        result = described_class.new(book_id: book.id, reader_id: other_reader.id).execute

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable)
        expect(result.errors[:base]).to eq("Book is already borrowed")
      end

      it "does not create another borrow record" do
        other_reader = create(:reader)
        expect {
          described_class.new(book_id: book.id, reader_id: other_reader.id).execute
        }.not_to change(BookBorrow, :count)
      end
    end

    context "when book was previously borrowed and returned" do
      before { create(:book_borrow, :returned, book: book, reader: reader) }

      it "allows borrowing again" do
        other_reader = create(:reader)
        result = described_class.new(book_id: book.id, reader_id: other_reader.id).execute

        expect(result).to be_success
        expect(result.status).to eq(:created)
      end
    end

    context "with missing attributes" do
      it "returns error for missing book_id" do
        result = described_class.new(book_id: nil, reader_id: reader.id).execute

        expect(result).to be_failure
        expect(result.errors[:book_id]).to be_present
      end

      it "returns error for missing reader_id" do
        result = described_class.new(book_id: book.id, reader_id: nil).execute

        expect(result).to be_failure
        expect(result.errors[:reader_id]).to be_present
      end
    end

    context "with non-existent references" do
      it "returns not_found for non-existent book" do
        result = described_class.new(
          book_id: "00000000-0000-0000-0000-000000000000",
          reader_id: reader.id
        ).execute

        expect(result).to be_failure
        expect(result.status).to eq(:not_found)
      end

      it "returns not_found for non-existent reader" do
        result = described_class.new(
          book_id: book.id,
          reader_id: "00000000-0000-0000-0000-000000000000"
        ).execute

        expect(result).to be_failure
        expect(result.status).to eq(:not_found)
      end
    end
  end
end
