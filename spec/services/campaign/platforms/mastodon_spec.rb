require "rails_helper"

RSpec.describe Campaign::Platforms::Mastodon do
  subject(:platform) { described_class.new }

  let(:publication) { create(:publication, platform_tag: "mastodon") }

  describe "#publish!" do
    it "returns a published Result with the remote id and url on success" do
      allow(platform).to receive(:post_status).and_return(
        ok: true, code: "200", body: { "id" => "12345", "url" => "https://mastodon.social/@me/12345" }
      )

      result = platform.publish!(publication)

      expect(result.status).to eq(:published)
      expect(result.remote_id).to eq("12345")
      expect(result.url).to eq("https://mastodon.social/@me/12345")
    end

    it "uploads attached media and includes the media ids in the status" do
      publication.post.media.attach(io: StringIO.new("img-bytes"), filename: "pic.png", content_type: "image/png")
      allow(platform).to receive(:upload_media).and_return("media-1")
      allow(platform).to receive(:post_status).and_return(
        ok: true, code: "200", body: { "id" => "9", "url" => "https://mastodon.social/@me/9" }
      )

      result = platform.publish!(publication)

      expect(platform).to have_received(:upload_media).once
      expect(platform).to have_received(:post_status).with(hash_including(media_ids: [ "media-1" ]))
      expect(result.status).to eq(:published)
    end

    it "returns a failed Result when the API responds with an error" do
      allow(platform).to receive(:post_status).and_return(
        ok: false, code: "422", body: { "error" => "Validation failed" }
      )

      result = platform.publish!(publication)

      expect(result.status).to eq(:failed)
      expect(result.message).to include("422")
    end

    it "returns a failed Result when the request raises" do
      allow(platform).to receive(:post_status).and_raise(SocketError.new("getaddrinfo failed"))

      result = platform.publish!(publication)

      expect(result.status).to eq(:failed)
      expect(result.error).to be_a(SocketError)
    end
  end
end
