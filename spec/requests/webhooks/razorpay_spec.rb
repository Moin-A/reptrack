require "rails_helper"

# Request specs for the Razorpay webhook endpoint: signature verification and
# handoff to Pay's webhook pipeline (persist + enqueue ProcessJob).
RSpec.describe "Razorpay webhooks", type: :request do
  let(:secret) { "whsec_test_secret" }
  let(:body)   { file_fixture("payment_processor/webhook/payment_captured.json").read }

  before { allow(Pay::RazorbackProcessor).to receive(:webhook_secret).and_return(secret) }

  def signature_for(payload)
    OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
  end

  def post_webhook(payload, signature:)
    post "/webhooks/razorpay",
      params: payload,
      headers: { "X-Razorpay-Signature" => signature, "CONTENT_TYPE" => "application/json" }
  end

  context "with a valid signature" do
    it "returns 200, stores a Pay::Webhook, and enqueues ProcessJob" do
      expect {
        post_webhook(body, signature: signature_for(body))
      }.to change(Pay::Webhook, :count).by(1)
        .and have_enqueued_job(Pay::Webhooks::ProcessJob)

      expect(response).to have_http_status(:ok)
      expect(Pay::Webhook.last).to have_attributes(processor: "razorback_processor", event_type: "payment.captured")
    end
  end

  context "with an invalid signature" do
    it "returns 400 and stores nothing" do
      expect {
        post_webhook(body, signature: "not-the-real-signature")
      }.not_to change(Pay::Webhook, :count)

      expect(response).to have_http_status(:bad_request)
    end
  end

  context "for an event with no registered handler" do
    let(:body) { { event: "payment.authorized", payload: {} }.to_json }

    it "acks with 200 but does not store or enqueue" do
      expect {
        post_webhook(body, signature: signature_for(body))
      }.not_to have_enqueued_job(Pay::Webhooks::ProcessJob)

      expect(response).to have_http_status(:ok)
      expect(Pay::Webhook.count).to eq(0)
    end
  end
end
