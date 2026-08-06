# Browser-facing Razorpay checkout, routed from the razorback engine.
#
# Inherits ActionController::Base, NOT ApplicationController — the latter is
# ActionController::API (this app is api_only) and cannot render templates.
class BillingController < ActionController::Base
  # Declared explicitly: the implicit layout is resolved from the controller
  # ancestry, and inheriting straight from ActionController::Base skips the
  # ApplicationController link that would normally imply layouts/application.
  layout "application"

  protect_from_forgery with: :exception

  # The Phase 3 payload rides through the (untrusted) browser, so reject anything
  # whose Razorpay HMAC doesn't check out before create ever runs.
  before_action :verify_payment_signature!, only: :create

  # Phase 1 — create the order server-side, hand it to the hosted modal.
  # Amount is in the smallest currency unit: 100 paise = ₹1.
  def checkout
    @amount   = 1000
    @currency = "INR"
    @key_id   = Razorpay.auth[:username]
    @email    = nil # workspace-level billing has no single email to prefill

    @order_id = ::Razorpay::Order.create(
      amount: @amount,
      currency: @currency,
      receipt: "test_#{SecureRandom.hex(6)}"
    ).id
  rescue ::Razorpay::Error => e
    render plain: "Razorpay order creation failed: #{e.message}", status: :bad_gateway
  end

  # Phase 3 — capture through the Pay processor. The signature was already
  # verified by the before_action, so the payload is trusted here. Take the
  # amount from Razorpay's order, never from the client.
  def create
    amount = ::Razorpay::Order.fetch(razorpay_create_params[:razorpay_order_id]).amount

    customer = billing_owner.set_payment_processor(:razorback_processor)
    charge = customer.charge(amount, payment_id: razorpay_create_params[:razorpay_payment_id], currency: "INR")

    render json: {
      id: charge.id, processor_id: charge.processor_id, amount: charge.amount,
      currency: charge.currency, status: charge.data["status"]
    }
  rescue Pay::Error, ::Razorpay::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  # Verifies Razorpay's checkout signature over "order_id|payment_id" with the
  # key secret. Renders 401 (and halts before create) if it doesn't match —
  # verify_payment_signature raises SecurityError on mismatch.
  def verify_payment_signature!
    ::Razorpay::Utility.verify_payment_signature(
      razorpay_order_id:   razorpay_create_params[:razorpay_order_id],
      razorpay_payment_id: razorpay_create_params[:razorpay_payment_id],
      razorpay_signature:  razorpay_create_params[:razorpay_signature]
    )
  rescue SecurityError
    render json: { error: "signature verification failed" }, status: :unauthorized
  end

  def razorpay_create_params
    params.permit(:razorpay_order_id, :razorpay_payment_id, :razorpay_signature)
  end

  # TEST-ONLY owner resolution. The workspace is the billable owner (one paying
  # customer per tenant), but the page auth / tenant-resolution decision is still
  # open — so this falls back to the first workspace. Replace with the current
  # tenant's workspace before this route is reachable in any environment that
  # matters.
  def billing_owner
    @billing_owner ||= Workspace.first
  end
end
