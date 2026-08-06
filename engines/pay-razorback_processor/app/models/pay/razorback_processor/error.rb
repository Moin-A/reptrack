module Pay
  module RazorbackProcessor
    # Wraps Razorpay SDK errors so callers can rescue Pay::Error uniformly,
    # mirroring Pay::Stripe::Error. `cause` holds the original Razorpay::Error.
    class Error < Pay::Error
      delegate :message, to: :cause
    end
  end
end
