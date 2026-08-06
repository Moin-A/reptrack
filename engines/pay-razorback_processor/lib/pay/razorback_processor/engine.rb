require "rails/engine"

module Pay
  # Razorpay ("razorback") processor for the Pay gem, packaged as a Rails engine
  # so it can be extracted into a standalone gem later. Deliberately NOT
  # isolate_namespace'd — it shares Pay's models and the host app's User.
  module RazorbackProcessor
    # Secret configured on the Razorpay dashboard webhook (test or live mode),
    # used to verify the X-Razorpay-Signature header on inbound webhooks.
    mattr_accessor :webhook_secret, default: ENV["RAZORPAY_WEBHOOK_SECRET"]

    class Engine < ::Rails::Engine
      # Register the razorback webhook handlers with Pay's delegator once the app
      # is initialized. Handler classes are referenced through lambdas (resolved
      # at call time) so they survive code reloading in development.
      initializer "pay.razorback_processor.webhooks" do
        Pay::Webhooks.configure do |events|
          events.subscribe "razorback_processor.payment.captured",
            ->(event) { Pay::RazorbackProcessor::Webhooks::PaymentCaptured.new.call(event) }
        end
      end
    end
  end
end
