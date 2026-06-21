require 'rails_helper'

RSpec.describe "Accounts export", type: :request do
  let(:user) { create(:user, confirmed_at: Time.now) }
  let(:xlsx_type) { "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }

  before do
    sign_in user
  end

  describe "GET /accounts/export" do
    it "downloads an .xlsx file of accounts" do
      create(:account, name: "Visible Inc", email: "contact@visible.example.com", access: "Public")

      get "/accounts/export"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(xlsx_type)
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.headers["Content-Disposition"]).to match(/accounts.*\.xlsx/)
    end
  end

  describe "GET /accounts.xlsx" do
    it "downloads via the format suffix" do
      get "/accounts.xlsx"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(xlsx_type)
    end
  end
end
