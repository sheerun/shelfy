require "rails_helper"

RSpec.describe Library::RegisterReader do
  describe "#execute" do
    context "with valid attributes" do
      it "creates a new reader" do
        result = described_class.new(
          serial_number: "100001",
          email: "test@example.com",
          full_name: "Jane Doe"
        ).execute

        expect(result).to be_success
        expect(result.status).to eq(:created)
        expect(result.data[:serial_number]).to eq("100001")
        expect(result.data[:email]).to eq("test@example.com")
        expect(result.data[:full_name]).to eq("Jane Doe")
        expect(result.data[:id]).to be_present
      end

      it "persists the reader in the database" do
        expect {
          described_class.new(
            serial_number: "100001",
            email: "test@example.com",
            full_name: "Jane Doe"
          ).execute
        }.to change(Reader, :count).by(1)
      end
    end

    context "with missing attributes" do
      it "returns validation errors for blank serial_number" do
        result = described_class.new(
          serial_number: "",
          email: "test@example.com",
          full_name: "Jane Doe"
        ).execute

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable)
        expect(result.errors[:serial_number]).to be_present
      end

      it "returns validation errors for blank email" do
        result = described_class.new(
          serial_number: "100001",
          email: "",
          full_name: "Jane Doe"
        ).execute

        expect(result).to be_failure
        expect(result.errors[:email]).to be_present
      end

      it "returns validation errors for blank full_name" do
        result = described_class.new(
          serial_number: "100001",
          email: "test@example.com",
          full_name: ""
        ).execute

        expect(result).to be_failure
        expect(result.errors[:full_name]).to be_present
      end
    end

    context "with duplicate email" do
      before { create(:reader, email: "taken@example.com") }

      it "returns error for duplicate email" do
        result = described_class.new(
          serial_number: "200001",
          email: "taken@example.com",
          full_name: "Another Reader"
        ).execute

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable)
      end
    end

    context "with duplicate serial_number" do
      before { create(:reader, serial_number: "100001") }

      it "returns error for duplicate serial_number" do
        result = described_class.new(
          serial_number: "100001",
          email: "unique@example.com",
          full_name: "Another Reader"
        ).execute

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable)
      end
    end

    context "with invalid serial_number format" do
      it "returns error for non-numeric serial_number" do
        result = described_class.new(
          serial_number: "abcdef",
          email: "test@example.com",
          full_name: "Jane Doe"
        ).execute

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable)
      end

      it "returns error for out-of-range serial_number" do
        result = described_class.new(
          serial_number: "099999",
          email: "test@example.com",
          full_name: "Jane Doe"
        ).execute

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable)
      end
    end
  end
end
