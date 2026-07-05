require "net/http"
require "json"

module Campaign
  module Platforms
    # Publishes a text post to a Facebook Page's feed using a Page access token.
    # Facebook only allows publishing to Pages (not personal profiles), so the
    # SocialAccount must store a `page_id` and a Page `access_token`.
    class Facebook < Base
      TAG = "facebook"
      REQUIRED_CREDENTIALS = %w[page_id access_token].freeze
      API_VERSION = "v21.0"

      def publish!(publication)
        credentials = publication.social_account.credentials

        response = post_feed(
          page_id: credentials["page_id"],
          access_token: credentials["access_token"],
          message: publication.post.content
        )

        if response[:ok]
          id = response[:body]["id"]
          Result.new(status: :published, remote_id: id, url: "https://www.facebook.com/#{id}")
        else
          Result.new(status: :failed, message: "Facebook API error (#{response[:code]}): #{response[:body]}")
        end
      rescue => e
        Result.new(status: :failed, message: "Facebook request failed", error: e)
      end

      # Live Page metadata via the stored Page token — no login flow needed.
      # Returns { ok:, body: { "id", "name", "category", "link", "followers_count", ... } }.
      def fetch_metadata(social_account)
        credentials = social_account.credentials
        uri = URI("https://graph.facebook.com/#{API_VERSION}/#{credentials["page_id"]}")
        uri.query = URI.encode_www_form(
          fields: "id,name,category,link,followers_count,fan_count,picture",
          access_token: credentials["access_token"]
        )

        res  = build_http(uri).request(Net::HTTP::Get.new(uri))
        body = parse_json(res.body)
        if res.is_a?(Net::HTTPSuccess)
          { ok: true, body: body }
        else
          { ok: false, message: "Facebook API error (#{res.code}): #{body}" }
        end
      rescue => e
        { ok: false, message: "Facebook request failed: #{e.message}" }
      end

      private

      # Posts to the Page feed; returns { ok:, code:, body: }. Network call
      # isolated so it can be stubbed in tests.
      def post_feed(page_id:, access_token:, message:)
        uri = URI("https://graph.facebook.com/#{API_VERSION}/#{page_id}/feed")
        http = build_http(uri)

        request = Net::HTTP::Post.new(uri)
        request.set_form_data(message: message, access_token: access_token)

        res = http.request(request)
        { ok: res.is_a?(Net::HTTPSuccess), code: res.code, body: parse_json(res.body) }
      end

      def build_http(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http
      end

      def parse_json(body)
        JSON.parse(body)
      rescue JSON::ParserError
        body
      end
    end
  end
end
