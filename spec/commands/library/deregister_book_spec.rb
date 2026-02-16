require "rails_helper"

RSpec.describe Library::DeregisterBook do
  describe "#execute" do
    context "when book exists" do
      let!(:book) { create(:book) }

      it "deletes the book" do
        expect {
          described_class.new(id: book.id).execute
        }.to change(Book, :count).by(-1)
      end

      it "returns success" do
        result = described_class.new(id: book.id).execute

        expect(result).to be_success
        expect(result.status).to eq(:ok)
      end
    end

    context "when book not found" do
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
