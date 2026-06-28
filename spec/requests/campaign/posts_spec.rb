require "rails_helper"

RSpec.describe "Campaign posts", type: :request do
  let(:user) { create(:user, confirmed_at: Time.now) }

  before { sign_in user }

  describe "POST /campaign/posts" do
    it "creates a post owned by the current user" do
      post "/campaign/posts", params: { campaign_post: { content: "New 6am strength class", kind: "ad" } }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body).to include("content" => "New 6am strength class", "kind" => "ad")
      expect(Campaign::Post.find(body["id"]).user).to eq(user)
    end

    it "attaches an uploaded file to the post's media" do
      pending("media not yet wired through create_params in Campaign::PostsController#create")
      file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/pic.png"), "image/png")

      post "/campaign/posts", params: { campaign_post: { content: "With an image" }, file: file }

      expect(response).to have_http_status(:created)
      created = Campaign::Post.find(JSON.parse(response.body)["id"])
      expect(created.media.count).to eq(1)
      expect(created.media.first.filename.to_s).to eq("pic.png")
    end

    it "returns 422 with errors when content is missing" do
      post "/campaign/posts", params: { campaign_post: { kind: "post" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to include(a_string_matching(/Content can't be blank/))
    end
  end
end
