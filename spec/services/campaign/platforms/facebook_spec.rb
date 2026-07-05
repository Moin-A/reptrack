require "rails_helper"

RSpec.describe Campaign::Platforms::Facebook do
  subject(:platform) { described_class.new }

  let(:publication) { create(:publication, platform_tag: "facebook") }

  describe "#publish!" do
    it "returns a published Result with the remote id and url on success" do
      allow(platform).to receive(:post_feed).and_return(
        ok: true, code: "200", body: { "id" => "1010_2020" }
      )

      result = platform.publish!(publication)

      expect(result.status).to eq(:published)
      expect(result.remote_id).to eq("1010_2020")
      expect(result.url).to eq("https://www.facebook.com/1010_2020")
    end

    it "returns a failed Result when the API responds with an error" do
      allow(platform).to receive(:post_feed).and_return(
        ok: false, code: "400", body: { "error" => "Invalid OAuth access token" }
      )

      result = platform.publish!(publication)

      expect(result.status).to eq(:failed)
      expect(result.message).to include("400")
    end

    it "returns a failed Result when the request raises" do
      allow(platform).to receive(:post_feed).and_raise(SocketError.new("getaddrinfo failed"))

      result = platform.publish!(publication)

      expect(result.status).to eq(:failed)
      expect(result.error).to be_a(SocketError)
    end
  end
end
