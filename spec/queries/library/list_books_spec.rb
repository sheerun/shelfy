require "rails_helper"

RSpec.describe Library::ListBooks do
  describe "#execute" do
    context "with no books" do
      it "returns empty list" do
        result = described_class.new.execute

        expect(result).to be_success
        expect(result.data[:data]).to be_empty
        expect(result.data[:meta][:total]).to eq(0)
      end
    end

    context "with books" do
      before { create_list(:book, 5) }

      it "returns all books" do
        result = described_class.new.execute

        expect(result).to be_success
        expect(result.data[:data].length).to eq(5)
        expect(result.data[:meta][:total]).to eq(5)
        expect(result.data[:meta][:page]).to eq(1)
      end

      it "includes status for each book" do
        result = described_class.new.execute

        result.data[:data].each do |book_data|
          expect(book_data[:status]).to eq("available")
        end
      end
    end

    context "status filtering" do
      let!(:available_book) { create(:book) }
      let!(:borrowed_book) { create(:book) }
      let!(:returned_book) { create(:book) }
      let(:reader) { create(:reader) }

      before do
        create(:book_borrow, book: borrowed_book, reader: reader)
        create(:book_borrow, :returned, book: returned_book, reader: reader)
      end

      it "filters borrowed books" do
        result = described_class.new(status: "borrowed").execute

        expect(result).to be_success
        expect(result.data[:data].length).to eq(1)
        expect(result.data[:data][0][:id]).to eq(borrowed_book.id)
        expect(result.data[:data][0][:status]).to eq("borrowed")
      end

      it "filters available books" do
        result = described_class.new(status: "available").execute

        expect(result).to be_success
        ids = result.data[:data].map { |b| b[:id] }
        expect(ids).to include(available_book.id)
        expect(ids).to include(returned_book.id)
        expect(ids).not_to include(borrowed_book.id)
      end

      it "returns all books without status filter" do
        result = described_class.new.execute

        expect(result.data[:data].length).to eq(3)
      end

      it "returns error for invalid status" do
        result = described_class.new(status: "lost").execute

        expect(result).to be_failure
        expect(result.errors[:status]).to be_present
      end
    end

    context "pagination" do
      before { create_list(:book, 25) }

      it "returns first page by default" do
        result = described_class.new.execute

        expect(result.data[:data].length).to eq(20)
        expect(result.data[:meta][:total]).to eq(25)
        expect(result.data[:meta][:page]).to eq(1)
        expect(result.data[:meta][:per_page]).to eq(20)
      end

      it "returns second page" do
        result = described_class.new(page: 2).execute

        expect(result.data[:data].length).to eq(5)
        expect(result.data[:meta][:page]).to eq(2)
      end

      it "respects per_page parameter" do
        result = described_class.new(per_page: 10).execute

        expect(result.data[:data].length).to eq(10)
        expect(result.data[:meta][:per_page]).to eq(10)
      end

      it "caps per_page at maximum" do
        result = described_class.new(per_page: 100).execute

        expect(result.data[:meta][:per_page]).to eq(50)
      end

      it "defaults page to 1 for invalid page" do
        result = described_class.new(page: 0).execute

        expect(result.data[:meta][:page]).to eq(1)
      end

      it "returns empty data for out of range page" do
        result = described_class.new(page: 999).execute

        expect(result).to be_success
        expect(result.data[:data]).to be_empty
        expect(result.data[:meta][:total]).to eq(25)
      end

      it "returns error for non-numeric page" do
        result = described_class.new(page: "abc").execute

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable)
        expect(result.errors[:page]).to be_present
      end
    end
  end
end
