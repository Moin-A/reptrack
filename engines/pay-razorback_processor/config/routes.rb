Pay::RazorbackProcessor::Engine.routes.draw do
  # Razorpay ("razorback") server-to-server webhooks. Host mounts this engine
  # (typically at "/"), so this resolves to POST /webhooks/razorpay.
  post "webhooks/razorpay", to: "pay/razorback_processor/webhooks#create"

  # Browser-facing checkout. The engine is deliberately not isolate_namespace'd,
  # so these resolve to the host app's ::BillingController.
  #
  #   GET  /billing/checkout — Phase 1: create a Razorpay order, render the modal
  #   POST /billing/charges  — Phase 3: verify the signature, then capture
  get  "billing/checkout", to: "billing#checkout"
  post "billing/orders",   to: "billing#create_order"   # Phase 1: mint an order for the chosen tier+period
  post "billing/charges",  to: "billing#create"
end
