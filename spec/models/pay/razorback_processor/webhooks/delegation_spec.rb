require "rails_helper"

# Verifies the engine initializer subscriptions are wired: processing a stored
# Pay::Webhook must dispatch through Pay's delegator to our handler (and
# therefore sync the charge). This is the glue the per-handler specs and the
# request spec don't exercise end-to-end.
RSpec.describe "razorback webhook delegation", type: :model do
  let(:workspace)       { create(:workspace) }
  let(:customer)   { workspace.set_payment_processor(:razorback_processor) }
  let(:event)      { JSON.parse(file_fixture("payment_processor/webhook/payment_captured.json").read) }
  let(:payment_id) { event.dig("payload", "payment", "entity", "id") }

  it "routes a processed payment.captured webhook to the handler" do
    charge = customer.charges.create!(processor_id: payment_id, amount: 1, data: {})
    record = Pay::Webhook.create!(processor: :razorback_processor, event_type: "payment.captured", event: event)

    record.process!

    expect(charge.reload.data["status"]).to eq("captured")
  end

  it "reports it is listening for the subscribed event types" do
    expect(Pay::Webhooks.delegator.listening?("razorback_processor.payment.captured")).to be(true)
  end
end
