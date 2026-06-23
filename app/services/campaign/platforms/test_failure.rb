module Campaign
  module Platforms
    # Fake adapter that always fails, for exercising the retry/failure path.
    class TestFailure < Base
      TAG = "test_failure"

      def publish!(_publication)
        Result.new(status: :failed, message: "Simulated publish failure")
      end
    end
  end
end
