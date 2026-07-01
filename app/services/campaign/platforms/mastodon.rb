require "net/http"
require "json"
require "stringio"

module Campaign
  module Platforms
    # Publishes a status (with optional image media) to a Mastodon instance
    # using the account's base_url + access_token credentials.
    class Mastodon < Base
      TAG = "mastodon"
      REQUIRED_CREDENTIALS = %w[base_url access_token].freeze

      def publish!(publication)
        credentials = publication.social_account.credentials

        # Step 1: upload each attached file, collecting their media ids.
        media_ids = publication.post.media.map { |attachment| upload_media(attachment, credentials) }

        # Step 2: post the status, referencing any uploaded media.
        response = post_status(
          base_url: credentials["base_url"],
          access_token: credentials["access_token"],
          status: publication.post.content,
          media_ids: media_ids
        )

        if response[:ok]
          Result.new(status: :published, remote_id: response[:body]["id"], url: response[:body]["url"])
        else
          Result.new(status: :failed, message: "Mastodon API error (#{response[:code]}): #{response[:body]}")
        end
      rescue => e
        Result.new(status: :failed, message: "Mastodon request failed", error: e)
      end

      private

      # Uploads one Active Storage attachment to /api/v2/media and returns its id.
      def upload_media(attachment, credentials)
        uri = URI.join(credentials["base_url"], "/api/v2/media")
        http = build_http(uri)

        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{credentials["access_token"]}"
        request.set_form(
          [ [ "file", StringIO.new(attachment.download),
              { filename: attachment.filename.to_s, content_type: attachment.content_type } ] ],
          "multipart/form-data"
        )

        res = http.request(request)
        raise "Mastodon media upload failed (#{res.code}): #{res.body}" unless res.is_a?(Net::HTTPSuccess)

        JSON.parse(res.body)["id"]
      end

      # Posts a status; returns { ok:, code:, body: }. Network call isolated so
      # it can be stubbed in tests.
      def post_status(base_url:, access_token:, status:, media_ids: [])
        uri = URI.join(base_url, "/api/v1/statuses")
        http = build_http(uri)

        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{access_token}"
        request["Content-Type"] = "application/json"
        body = { status: status }
        body[:media_ids] = media_ids if media_ids.any?
        request.body = body.to_json

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
