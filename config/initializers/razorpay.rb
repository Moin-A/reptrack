# frozen_string_literal: true

# Configures the Razorpay SDK once at boot. Every server-side call
# (Order.create, Payment.fetch, capture, refund) authenticates with these,
# and Razorpay::Utility.verify_payment_signature derives the expected HMAC
# from the secret via Razorpay.auth[:password].
#
# Test credentials look like rzp_test_XXXXXXXX; live ones rzp_live_XXXXXXXX.
#
#   key_id     — public. Safe to embed in a page; the checkout modal needs it.
#   key_secret — private. Never send it to the browser.
#
# Read from ENV first so deployments can inject them, falling back to encrypted
# credentials for local development:
#
#   bin/rails credentials:edit
#   razorpay:
#     key_id: rzp_test_xxx
#     key_secret: xxx
key_id     = ENV["RAZORPAY_KEY_ID"].presence     || Rails.application.credentials.dig(:razorpay, :key_id)
key_secret = ENV["RAZORPAY_KEY_SECRET"].presence || Rails.application.credentials.dig(:razorpay, :key_secret)

if key_id.present? && key_secret.present?
  Razorpay.setup(key_id, key_secret)
elsif !Rails.env.test?
  # Don't abort boot — specs stub the SDK and never need real credentials.
  # Any live API call will fail loudly on its own.
  Rails.logger.warn("[razorpay] RAZORPAY_KEY_ID/RAZORPAY_KEY_SECRET not set; Razorpay API calls will fail")
end
