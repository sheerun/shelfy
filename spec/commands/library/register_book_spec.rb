require "rails_helper"

RSpec.describe Library::RegisterBook do
  describe "#execute" do
    context "with valid attributes" do
      it "creates a new book" do
        result = described_class.new(
          serial_number: "100001",
          title: "The Great Gatsby",
          author: "F. Scott Fitzgerald"
        ).execute

        expect(result).to be_success
        expect(result.status).to eq(:created)
        expect(result.data[:serial_number]).to eq("100001")
        expect(result.data[:title]).to eq("The Great Gatsby")
        expect(result.data[:author]).to eq("F. Scott Fitzgerald")
        expect(result.data[:id]).to be_present
      end

      it "persists the book in the database" do
        expect {
          described_class.new(
            serial_number: "100001",
            title: "The Great Gatsby",
            author: "F. Scott Fitzgerald"
          ).execute
        }.to change(Book, :count).by(1)
      end
    end

    context "with missing attributes" do
      it "returns validation errors for blank serial_number" do
        result = described_class.new(
          serial_number: "",
          title: "The Great Gatsby",
          author: "F. Scott Fitzgerald"
        ).execute

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable)
        expect(result.errors[:serial_number]).to be_present
      end

      it "returns validation errors for blank title" do
        result = described_class.new(
          serial_number: "100001",
          title: "",
          author: "F. Scott Fitzgerald"
        ).execute

        expect(result).to be_failure
        expect(result.errors[:title]).to be_present
      end

      it "returns validation errors for blank author" do
        result = described_class.new(
          serial_number: "100001",
          title: "The Great Gatsby",
          author: ""
        ).execute

        expect(result).to be_failure
        expect(result.errors[:author]).to be_present
      end
    end

    context "with duplicate serial_number" do
      before { create(:book, serial_number: "100001") }

      it "returns error for duplicate serial_number" do
        result = described_class.new(
          serial_number: "100001",
          title: "Another Book",
          author: "Another Author"
        ).execute

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable)
      end
    end

    context "with invalid serial_number format" do
      it "returns error for non-numeric serial_number" do
        result = described_class.new(
          serial_number: "abcdef",
          title: "The Great Gatsby",
          author: "F. Scott Fitzgerald"
        ).execute

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable)
      end

      it "returns error for out-of-range serial_number" do
        result = described_class.new(
          serial_number: "099999",
          title: "The Great Gatsby",
          author: "F. Scott Fitzgerald"
        ).execute

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable)
      end
    end
  end
end
