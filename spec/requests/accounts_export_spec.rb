require 'rails_helper'

RSpec.describe "Accounts export", type: :request do
  let(:user) { create(:user, confirmed_at: Time.now) }

  before do
    sign_in user
  end

  describe "GET /accounts/export" do
    it "downloads an Excel sheet of accounts" do
      create(:account, name: "Visible Inc", email: "contact@visible.example.com", access: "Public")

      get "/accounts/export"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/vnd.ms-excel")
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.headers["Content-Disposition"]).to match(/accounts.*\.xls/)
      expect(response.body).to include("Visible Inc")
    end

    it "only includes accounts visible to the current user" do
      create(:account, name: "Mine LLC", email: "me@mine.example.com", access: "Private", user: user)
      create(:account, name: "Secret Co", email: "hq@secret.example.com", access: "Private",
        user: create(:user, confirmed_at: Time.now))

      get "/accounts/export"

      expect(response.body).to include("Mine LLC")
      expect(response.body).not_to include("Secret Co")
    end
  end

  describe "GET /accounts.xls" do
    it "downloads the same Excel sheet via the format suffix" do
      create(:account, name: "Visible Inc", email: "contact@visible.example.com", access: "Public")

      get "/accounts.xls"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/vnd.ms-excel")
      expect(response.body).to include("Visible Inc")
    end
  end
end
