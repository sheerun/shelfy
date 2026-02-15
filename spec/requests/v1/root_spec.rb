require "rails_helper"

RSpec.describe "V1 Root", type: :request do
  describe "GET /v1" do
    it "redirects to API documentation" do
      get "/v1"
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to("/v1/docs")
    end
  end
end
