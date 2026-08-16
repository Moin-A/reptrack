Pay::RazorbackProcessor::Engine.routes.draw do
  # Razorpay ("razorback") server-to-server webhooks. Host mounts this engine
  # (typically at "/"), so this resolves to POST /webhooks/razorpay.
  #
  # Browser-facing routes (billing/checkout, billing/orders, billing/charges,
  # billing/workspace) now live in the host app's config/routes.rb so their
  # path helpers register on the application route set — OnboardingFlow, mixed
  # into the host controllers, resolves them via bare `send(:billing_*_path)`.
  post "webhooks/razorpay", to: "pay/razorback_processor/webhooks#create"
end
