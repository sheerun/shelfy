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
