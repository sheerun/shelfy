require "rails_helper"

RSpec.describe Library::DeregisterReader do
  describe "#execute" do
    context "when reader exists" do
      let!(:reader) { create(:reader) }

      it "deletes the reader" do
        expect {
          described_class.new(id: reader.id).execute
        }.to change(Reader, :count).by(-1)
      end

      it "returns success" do
        result = described_class.new(id: reader.id).execute

        expect(result).to be_success
        expect(result.status).to eq(:ok)
      end
    end

    context "when reader not found" do
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
