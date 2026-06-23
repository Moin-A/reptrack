module Campaign
  module Platforms
    # Fake adapter that always skips, for exercising the skipped path.
    class TestSkipped < Base
      TAG = "test_skipped"

      def publish!(_publication)
        Result.new(status: :skipped, message: "Simulated skip")
      end
    end
  end
end
