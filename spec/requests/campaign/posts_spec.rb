require "rails_helper"

RSpec.describe "Campaign posts", type: :request do
  let(:user) { create(:user, confirmed_at: Time.now) }

  before { sign_in user }

  describe "POST /campaign/posts" do
    it "creates a post owned by the current user" do
      post "/campaign/posts", params: { campaign_post: { content: "New 6am strength class", kind: "ad" } }

      expect(response).to have_http_status(:created)
      data = JSON.parse(response.body)["data"]
      expect(data["attributes"]).to include("content" => "New 6am strength class", "kind" => "ad")
      expect(Campaign::Post.find(data["id"]).user).to eq(user)
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

  describe "PATCH /campaign/posts/:id" do
    it "updates the user's own post" do
      record = create(:post, user: user, content: "old content")

      patch "/campaign/posts/#{record.id}", params: { campaign_post: { content: "new content", url: "https://reptrack.io/x" } }

      expect(response).to have_http_status(:ok)
      expect(record.reload.content).to eq("new content")
      expect(record.url).to eq("https://reptrack.io/x")
    end

    it "does not update a post owned by another user" do
      other_post = create(:post, content: "theirs")

      expect {
        patch "/campaign/posts/#{other_post.id}", params: { campaign_post: { content: "hacked" } }
      }.to raise_error(CanCan::AccessDenied)

      expect(other_post.reload.content).to eq("theirs")
    end
  end

  describe "DELETE /campaign/posts/:id" do
    it "deletes the user's own post" do
      record = create(:post, user: user)

      delete "/campaign/posts/#{record.id}"

      expect(response).to have_http_status(:no_content)
      expect(Campaign::Post.exists?(record.id)).to be(false)
    end

    it "does not delete a post owned by another user" do
      other_post = create(:post) # different user

      expect {
        delete "/campaign/posts/#{other_post.id}"
      }.to raise_error(CanCan::AccessDenied)

      expect(Campaign::Post.exists?(other_post.id)).to be(true)
    end
  end
end
