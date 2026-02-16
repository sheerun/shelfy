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
