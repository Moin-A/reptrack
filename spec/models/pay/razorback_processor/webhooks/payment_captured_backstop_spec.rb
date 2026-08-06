require "rails_helper"

# The reconciliation backstop.
#
# Capture is synchronous, so Customer#charge normally records the Pay::Charge
# itself and the payment.captured webhook is a redundant second copy. This spec
# covers the case where that duplicate stops being redundant: Razorpay captured
# the money but the local write never happened — the process crashed, the DB was
# unreachable, or the browser died before the capture request even landed.
#
# The same path covers out-of-band captures (auto-capture, or a capture issued
# from the Razorpay dashboard), where no synchronous response ever reaches us.
#
# ASSUMPTION: the customer is identified by pay_customer_id in the order's
# notes, which Razorpay echoes onto the payment entity. Phase 1 does not set
# this yet — Razorpay::Order.create is called without notes, so the fixture
# ships notes: null and this spec injects them. If you resolve the customer a
# different way (a local orders table, for instance), rewrite this setup.
RSpec.describe Pay::RazorbackProcessor::Webhooks::PaymentCaptured, "reconciliation backstop", type: :model do
  let(:workspace)     { create(:workspace) }
  let(:customer) { workspace.set_payment_processor(:razorback_processor) }

  let(:event) do
    raw = JSON.parse(file_fixture("payment_processor/webhook/payment_captured.json").read)
    raw["payload"]["payment"]["entity"]["notes"] = { "pay_customer_id" => customer.id }
    raw
  end
  let(:entity)     { event.dig("payload", "payment", "entity") }
  let(:payment_id) { entity["id"] }

  context "when the capture succeeded but no local charge was written" do
    it "records the charge from the webhook payload" do
      expect { described_class.new.call(event) }
        .to change(Pay::RazorbackProcessor::Charge, :count).by(1)
    end

    it "attaches the charge to the customer named in the order notes" do
      described_class.new.call(event)

      expect(Pay::RazorbackProcessor::Charge.for_processor_id(payment_id).customer).to eq(customer)
    end

    it "copies the payment entity onto the recovered charge" do
      described_class.new.call(event)

      charge = Pay::RazorbackProcessor::Charge.for_processor_id(payment_id)
      expect(charge.amount).to eq(entity["amount"])
      expect(charge.amount_refunded).to eq(entity["amount_refunded"])
      expect(charge.data["status"]).to eq("captured")
    end
  end

  # Razorpay retries webhooks until it gets a 2xx, so the same event can arrive
  # several times. Recovery must not produce duplicate ledger rows.
  context "when the same event is delivered twice" do
    it "records the charge only once" do
      described_class.new.call(event)

      expect { described_class.new.call(event) }
        .not_to change(Pay::RazorbackProcessor::Charge, :count)
    end
  end
end
