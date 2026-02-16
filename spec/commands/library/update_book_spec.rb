require "rails_helper"

RSpec.describe Library::UpdateBook do
  describe "#execute" do
    let!(:book) { create(:book, serial_number: "100001", title: "Original Title", author: "Original Author") }

    context "with valid attributes" do
      it "updates the book's title" do
        result = described_class.new(id: book.id, title: "Updated Title").execute

        expect(result).to be_success
        expect(result.data[:title]).to eq("Updated Title")
        expect(result.data[:id]).to eq(book.id)
      end

      it "updates the book's author" do
        result = described_class.new(id: book.id, author: "Updated Author").execute

        expect(result).to be_success
        expect(result.data[:author]).to eq("Updated Author")
      end

      it "updates the book's serial_number" do
        result = described_class.new(id: book.id, serial_number: "200001").execute

        expect(result).to be_success
        expect(result.data[:serial_number]).to eq("200001")
      end

      it "returns the full book object after update" do
        result = described_class.new(id: book.id, title: "Updated Title").execute

        expect(result.data[:serial_number]).to eq("100001")
        expect(result.data[:title]).to eq("Updated Title")
        expect(result.data[:author]).to eq("Original Author")
      end
    end

    context "when book not found" do
      it "returns not_found status" do
        result = described_class.new(id: "00000000-0000-0000-0000-000000000000", title: "Nope").execute

        expect(result).to be_failure
        expect(result.status).to eq(:not_found)
      end
    end

    context "with duplicate serial_number" do
      let!(:other_book) { create(:book, serial_number: "200001") }

      it "returns error for duplicate serial_number" do
        result = described_class.new(id: book.id, serial_number: "200001").execute

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable)
      end
    end

    context "with invalid serial_number" do
      it "returns error for invalid format" do
        result = described_class.new(id: book.id, serial_number: "abc").execute

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable)
      end
    end
  end
end
