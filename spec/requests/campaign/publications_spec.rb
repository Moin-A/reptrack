require "rails_helper"

RSpec.describe "Campaign publications", type: :request do
  let(:user) { create(:user, confirmed_at: Time.now) }

  before do
    sign_in user
    allow(Campaign::PublishPublicationJob).to receive(:perform_later)
  end

  describe "POST /campaign/publications" do
    it "launches a post to the given social accounts" do
      post_record = create(:post, user: user)
      account = create(:social_account, user: user)

      post "/campaign/publications", params: { post_id: post_record.id, social_account_ids: [ account.id ] }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["publications"].size).to eq(1)
      expect(body["publications"].first).to include("social_account_id" => account.id, "status" => "ready")
    end

    it "returns 404 when launching a post that isn't the user's" do
      other_post = create(:post) # different user

      post "/campaign/publications", params: { post_id: other_post.id, social_account_ids: [] }

      expect(response).to have_http_status(:not_found)
    end
  end
end
