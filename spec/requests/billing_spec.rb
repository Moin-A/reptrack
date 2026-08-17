require "rails_helper"

  # Request specs for the browser-facing Razorpay checkout (BillingController),
  # routed through the razorback engine. All Razorpay SDK calls are stubbed, so no
  # network/credentials are needed — Razorpay.auth is stubbed because the test env
  # never runs Razorpay.setup.
  RSpec.describe "Billing (Razorpay checkout)", type: :request do
  let(:success)    { show_response("payment_processor/customer", filename: "success") }
  let(:user)       { create(:user, confirmed_at: Time.current) }

  before { sign_in user }

  describe "GET /billing/checkout" do
    before { allow(Razorpay).to receive(:auth).and_return(username: "rzp_test_key") }

    it "renders the pricing page (no order created yet)" do
      expect(::Razorpay::Order).not_to receive(:create)

      get "/billing/checkout"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Simple pricing", "Starter", "Growth", "Most popular")
    end
  end

  describe "POST /billing/orders (mint order for tier + period)" do
    before { allow(Razorpay).to receive(:auth).and_return(username: "rzp_test_key") }

    def post_order(tier:, period:)
      allow(::Razorpay::Order).to receive(:create).and_return(double(id: "order_XYZ"))
      post "/billing/orders", params: { tier: tier, period: period }
    end

    it "creates a monthly order at the tier's monthly amount" do
      post_order(tier: "starter", period: "monthly")

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include("order_id" => "order_XYZ", "amount" => 50_000)
    end

    it "applies the 20% annual discount (monthly * 12 * 0.8)" do
      post_order(tier: "starter", period: "annual")

      expect(JSON.parse(response.body)["amount"]).to eq(480_000)
    end

    it "rejects an unknown tier" do
      post "/billing/orders", params: { tier: "enterprise", period: "monthly" }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 502 when Razorpay order creation fails" do
      allow(::Razorpay::Order).to receive(:create).and_raise(::Razorpay::Error.new("boom", 400))

      post "/billing/orders", params: { tier: "starter", period: "monthly" }

      expect(response).to have_http_status(:bad_gateway)
    end
  end

  describe "POST /billing/charges (Phase 3)" do
    before do
      allow(::Razorpay::Utility).to receive(:verify_payment_signature).and_return(true)
      allow(::Razorpay::Order).to receive(:fetch).and_return(double(amount: success["amount"]))
    end

    def post_charge(payment_id: success["id"], signature: "valid_sig")
      post "/billing/charges", params: {
        razorpay_order_id: "order_ABC",
        razorpay_payment_id: payment_id,
        razorpay_signature: signature
      }
    end

    it "verifies, captures, and returns the charge as JSON" do
      payment = stub_api_response(::Razorpay::Payment, :fetch, success)
      stub_api_response(payment, :capture, success)
      
      expect { post_charge }.to change(Pay::RazorbackProcessor::Charge, :count).by(1)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include(
        "processor_id" => success["id"],
        "amount" => success["amount"],
        "status" => "captured"
      )
    end

    it "returns 401 when the signature is invalid" do
      allow(::Razorpay::Utility).to receive(:verify_payment_signature).and_raise(SecurityError)

      expect { post_charge(signature: "bad") }.not_to change(Pay::RazorbackProcessor::Charge, :count)
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 422 when Razorpay rejects the capture" do
      # Must be an un-captured payment, otherwise charge skips the capture call.
      authorized = show_response("payment_processor/customer", filename: "authorized")
      payment = stub_api_response(::Razorpay::Payment, :fetch, authorized)
      allow(payment).to receive(:capture).and_raise(::Razorpay::BadRequestError.new("insufficient funds", 400))

      post_charge(payment_id: authorized["id"])

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
