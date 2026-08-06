module Pay
  module RazorbackProcessor
    # Receives Razorpay webhooks. Verifies the HMAC-SHA256 signature, then stores
    # the event as a Pay::Webhook and hands it to Pay::Webhooks::ProcessJob (Sidekiq)
    # for dispatch to the registered handlers. Fast + synchronous work only:
    # verify -> persist -> enqueue -> 200.
    #
    # ActionController::API base means no CSRF token is expected (this is a
    # server-to-server POST, not a browser form).
    class WebhooksController < ActionController::API
      def create
        verify_signature!
        queue_event(JSON.parse(request.raw_post))
        head :ok
      rescue SecurityError, JSON::ParserError
        head :bad_request
      end

      private

      # Razorpay::Utility.verify_webhook_signature raises SecurityError on mismatch.
      def verify_signature!
        secret = Pay::RazorbackProcessor.webhook_secret
        raise SecurityError, "razorpay webhook secret not configured" if secret.blank?

        ::Razorpay::Utility.verify_webhook_signature(
          request.raw_post,
          request.headers["X-Razorpay-Signature"].to_s,
          secret
        )
      end

      def queue_event(event)
        event_type = event["event"]
        return unless Pay::Webhooks.delegator.listening?("razorback_processor.#{event_type}")

        record = Pay::Webhook.create!(processor: :razorback_processor, event_type: event_type, event: event)
        Pay::Webhooks::ProcessJob.perform_later(record)
      end
    end
  end
end
