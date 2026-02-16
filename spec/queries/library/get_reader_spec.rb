require "rails_helper"

RSpec.describe Library::GetReader do
  describe "#execute" do
    context "when reader exists" do
      let!(:reader) { create(:reader) }

      it "returns the reader" do
        result = described_class.new(id: reader.id).execute

        expect(result).to be_success
        expect(result.data[:id]).to eq(reader.id)
        expect(result.data[:serial_number]).to eq(reader.serial_number)
        expect(result.data[:email]).to eq(reader.email)
        expect(result.data[:full_name]).to eq(reader.full_name)
      end
    end

    context "when reader does not exist" do
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
