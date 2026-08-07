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

  # Plans. Amounts are in the smallest currency unit (paise): 399_900 = ₹3,999.
  # Annual is derived (12 months, 20% off) — see annual_amount. Adjust here.
  ANNUAL_DISCOUNT = 0.8
  TIERS = [
    {
      key: "starter",
      name: "Starter",
      tagline: "For single-location gyms getting off spreadsheets.",
      amount_monthly: 50_000,
      popular: false,
      features: [
        "Up to 300 active members",
        "Membership & billing",
        "Check-in & door access",
        "Email support"
      ]
    },
    {
      key: "growth",
      name: "Growth",
      tagline: "For multi-location gyms and growing teams.",
      amount_monthly: 90_000,
      popular: true,
      features: [
        "Unlimited active members",
        "Everything in Starter",
        "Multi-location management",
        "Campaigns & automations",
        "Priority support"
      ]
    }
  ].freeze

  # Annual total in paise: monthly * 12 * (1 - discount).
  def self.annual_amount(monthly) = (monthly * 12 * ANNUAL_DISCOUNT).round

  # Renders the pricing page. No Razorpay order is created here — the order is
  # minted on "Get Started" click (create_order) for the chosen tier + period,
  # so the charged amount always matches what the user selected.
  def checkout
    @key_id       = Razorpay.auth&.dig(:username)
    @frontend_url = ENV["FRONTEND_URL"].presence || "http://localhost:3001"
    @tiers = TIERS.map { |tier| tier.merge(amount_annual: self.class.annual_amount(tier[:amount_monthly])) }
  end

  # Creates a Razorpay order for the selected tier + billing period, called by
  # the pricing controller before it opens the hosted modal. Amount comes from
  # the server-side TIERS, never the client.
  def create_order
    tier = TIERS.find { |t| t[:key] == params[:tier] }
    return render(json: { error: "unknown tier" }, status: :unprocessable_entity) if tier.nil?

    amount = params[:period] == "annual" ? self.class.annual_amount(tier[:amount_monthly]) : tier[:amount_monthly]
    order  = ::Razorpay::Order.create(amount: amount, currency: "INR", receipt: "test_#{SecureRandom.hex(6)}")

    render json: { order_id: order.id, amount: amount, key: @key_id || Razorpay.auth&.dig(:username) }
  rescue ::Razorpay::Error => e
    render json: { error: e.message }, status: :bad_gateway
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
