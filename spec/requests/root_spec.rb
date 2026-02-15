require "rails_helper"

RSpec.describe "API root", type: :request do
  describe "GET /" do
    it "redirects to API documentation" do
      get "/"
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to("/docs")
    end
  end
end
