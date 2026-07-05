require "rails_helper"

RSpec.describe "Campaign social accounts", type: :request do
  let(:user) { create(:user, confirmed_at: Time.now) }

  before { sign_in user }

  describe "GET /campaign/social_accounts" do
    it "lists the current user's accounts without credentials" do
      account = create(:social_account, user: user, platform_tag: "facebook", label: "My Page")
      create(:social_account) # another user's — must not appear

      get "/campaign/social_accounts"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.size).to eq(1)
      expect(body.first).to include("id" => account.id, "platform_tag" => "facebook", "label" => "My Page")
      expect(body.first).not_to have_key("credentials")
    end
  end

  describe "POST /campaign/social_accounts (connect)" do
    it "creates a facebook account from form credentials, validated via metadata" do
      adapter = instance_double(Campaign::Platforms::Facebook)
      allow_any_instance_of(Campaign::MatchesPlatformApi).to receive(:match).and_return(adapter)
      allow(adapter).to receive(:fetch_metadata).and_return(ok: true, body: { "name" => "My Test Page" })

      post "/campaign/social_accounts", params: {
        platform_tag: "facebook", label: "Page 123",
        credentials: { page_id: "123", access_token: "tok" }
      }

      expect(response).to have_http_status(:created)
      account = Campaign::SocialAccount.find_by(user: user, platform_tag: "facebook")
      expect(account.credentials).to eq("page_id" => "123", "access_token" => "tok")
      expect(account.label).to eq("My Test Page")
      expect(account.active).to be(true)
    end

    it "raises error if invalid platform_tag is provided" do
      post "/campaign/social_accounts", params: {
        platform_tag: "invalid", label: "Invalid Account",
        credentials: { handle: "@invalid", api_key: "invalid" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to include("Platform not supported — choose Facebook, Mastodon, X, or Instagram.")
    end

    it "creates an account without validation when the platform has no adapter" do
      post "/campaign/social_accounts", params: {
        platform_tag: "x", label: "@me",
        credentials: { handle: "@me", api_key: "k" }
      }

      expect(response).to have_http_status(:created)
      expect(Campaign::SocialAccount.find_by(user: user, platform_tag: "x").active).to be(true)
    end

    it "rejects unknown platforms" do
      post "/campaign/social_accounts", params: { platform_tag: "myspace", credentials: { a: "b" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /campaign/social_accounts/:id/refresh" do
    let(:account) { create(:social_account, user: user, platform_tag: "facebook", label: "Old Label") }
    let(:adapter) { instance_double(Campaign::Platforms::Facebook) }

    before do
      allow_any_instance_of(Campaign::MatchesPlatformApi).to receive(:match).and_return(adapter)
    end

    it "syncs label and returns live metadata when the credentials work" do
      allow(adapter).to receive(:fetch_metadata).and_return(
        ok: true, body: { "name" => "Fresh Name", "followers_count" => 42 }
      )

      post "/campaign/social_accounts/#{account.id}/refresh"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include("label" => "Fresh Name", "active" => true)
      expect(body["metadata"]).to include("followers_count" => 42)
      expect(account.reload.label).to eq("Fresh Name")
    end

    it "marks the account inactive when the platform rejects the credentials" do
      allow(adapter).to receive(:fetch_metadata).and_return(ok: false, message: "Facebook API error (190)")

      post "/campaign/social_accounts/#{account.id}/refresh"

      expect(response).to have_http_status(:unprocessable_entity)
      expect(account.reload.active).to be(false)
      expect(JSON.parse(response.body)["errors"]).to include(a_string_matching(/190/))
    end

    it "returns 404 for another user's account" do
      other = create(:social_account)

      post "/campaign/social_accounts/#{other.id}/refresh"

      expect(response).to have_http_status(:not_found)
    end
  end
end
