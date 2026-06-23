module Campaign
  module Platforms
    # Outcome of a platform publish attempt. `status` is one of
    # :published, :skipped, or :failed.
    Result = Struct.new(:status, :remote_id, :url, :message, :error, keyword_init: true) do
      def published? = status == :published
      def skipped?   = status == :skipped
      def failed?    = status == :failed
    end
  end
end
