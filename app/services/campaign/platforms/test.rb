module Campaign
  module Platforms
    # Fake adapter for building and testing the pipeline without network calls.
    class Test < Base
      TAG = "test"

      def publish!(publication)
        Result.new(
          status: :published,
          remote_id: "test-#{publication.id}",
          url: "https://test.example/posts/#{publication.id}"
        )
      end
    end
  end
end
