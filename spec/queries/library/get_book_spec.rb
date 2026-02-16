require "rails_helper"

RSpec.describe Library::GetBook do
  describe "#execute" do
    context "when book exists" do
      let!(:book) { create(:book) }

      it "returns the book" do
        result = described_class.new(id: book.id).execute

        expect(result).to be_success
        expect(result.data[:id]).to eq(book.id)
        expect(result.data[:serial_number]).to eq(book.serial_number)
        expect(result.data[:title]).to eq(book.title)
        expect(result.data[:author]).to eq(book.author)
      end

      it "returns status field" do
        result = described_class.new(id: book.id).execute

        expect(result.data[:status]).to eq("available")
      end

      it "returns empty borrows when never borrowed" do
        result = described_class.new(id: book.id).execute

        expect(result.data[:borrows]).to eq([])
      end
    end

    context "when book has borrows" do
      let(:book) { create(:book) }
      let(:reader1) { create(:reader) }
      let(:reader2) { create(:reader) }

      it "returns borrows sorted most recent first" do
        create(:book_borrow, :returned, book: book, reader: reader1,
          borrow_date: 60.days.ago.to_date, due_date: 30.days.ago.to_date, return_date: 30.days.ago.to_date)
        create(:book_borrow, book: book, reader: reader2)

        result = described_class.new(id: book.id).execute

        expect(result.data[:borrows].length).to eq(2)
        expect(result.data[:borrows][0][:reader_card_number]).to eq(reader2.serial_number)
        expect(result.data[:borrows][1][:reader_card_number]).to eq(reader1.serial_number)
      end

      it "shows status as borrowed when actively borrowed" do
        create(:book_borrow, book: book, reader: reader1)

        result = described_class.new(id: book.id).execute

        expect(result.data[:status]).to eq("borrowed")
      end

      it "shows status as available when all borrows returned" do
        create(:book_borrow, :returned, book: book, reader: reader1)

        result = described_class.new(id: book.id).execute

        expect(result.data[:status]).to eq("available")
      end

      it "includes borrow details" do
        borrow = create(:book_borrow, book: book, reader: reader1)

        result = described_class.new(id: book.id).execute

        borrow_data = result.data[:borrows][0]
        expect(borrow_data[:reader_card_number]).to eq(reader1.serial_number)
        expect(borrow_data[:reader_email]).to eq(reader1.email)
        expect(borrow_data[:borrow_date]).to eq(borrow.borrow_date)
        expect(borrow_data[:due_date]).to eq(borrow.due_date)
        expect(borrow_data[:return_date]).to be_nil
      end
    end

    context "when book does not exist" do
      it "returns not_found status" do
        result = described_class.new(id: "00000000-0000-0000-0000-000000000000").execute

        expect(result).to be_failure
        expect(result.status).to eq(:not_found)
      end
    end

    context "when id is missing" do
      it "returns validation errors" do
        result = described_class.new(id: nil).execute

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable)
        expect(result.errors[:id]).to be_present
      end
    end
  end
end
