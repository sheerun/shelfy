require "rails_helper"

RSpec.describe Library::UpdateReader do
  describe "#execute" do
    let!(:reader) { create(:reader, serial_number: "100001", email: "original@example.com", full_name: "Original Name") }

    context "with valid attributes" do
      it "updates the reader's full_name" do
        result = described_class.new(id: reader.id, full_name: "Updated Name").execute

        expect(result).to be_success
        expect(result.data[:full_name]).to eq("Updated Name")
        expect(result.data[:id]).to eq(reader.id)
      end

      it "updates the reader's email" do
        result = described_class.new(id: reader.id, email: "updated@example.com").execute

        expect(result).to be_success
        expect(result.data[:email]).to eq("updated@example.com")
      end

      it "updates the reader's serial_number" do
        result = described_class.new(id: reader.id, serial_number: "200001").execute

        expect(result).to be_success
        expect(result.data[:serial_number]).to eq("200001")
      end

      it "returns the full reader object after update" do
        result = described_class.new(id: reader.id, full_name: "Updated Name").execute

        expect(result.data[:serial_number]).to eq("100001")
        expect(result.data[:email]).to eq("original@example.com")
        expect(result.data[:full_name]).to eq("Updated Name")
      end
    end

    context "when reader not found" do
      it "returns not_found status" do
        result = described_class.new(id: "00000000-0000-0000-0000-000000000000", full_name: "Nope").execute

        expect(result).to be_failure
        expect(result.status).to eq(:not_found)
      end
    end

    context "with duplicate email" do
      let!(:other_reader) { create(:reader, email: "taken@example.com") }

      it "returns error for duplicate email" do
        result = described_class.new(id: reader.id, email: "taken@example.com").execute

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable)
      end
    end

    context "with invalid serial_number" do
      it "returns error for invalid format" do
        result = described_class.new(id: reader.id, serial_number: "abc").execute

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable)
      end
    end
  end
end
