require "rails_helper"

RSpec.describe Pay::RazorbackProcessor::Webhooks::PaymentCaptured, type: :model do
  let(:workspace)       { create(:workspace) }
  let(:customer)   { workspace.set_payment_processor(:razorback_processor) }
  let(:event)      { JSON.parse(file_fixture("payment_processor/webhook/payment_captured.json").read) }
  let(:entity)     { event.dig("payload", "payment", "entity") }
  let(:payment_id) { entity["id"] }

  context "when a matching charge exists" do
    let!(:charge) { customer.charges.create!(processor_id: payment_id, amount: 1, data: {}) }

    it "syncs the charge to the payment entity" do
      described_class.new.call(event)

      charge.reload
      expect(charge.amount).to eq(entity["amount"])
      expect(charge.amount_refunded).to eq(entity["amount_refunded"])
      expect(charge.data["status"]).to eq("captured")
    end
  end

  # The fixture ships notes: null, so this event names no Pay::Customer. A charge
  # belongs to a customer, so there is nothing to attach one to and the event is
  # dropped. Recovery for events that DO name a customer is covered in
  # payment_captured_backstop_spec.rb — this is the case that stays a no-op.
  context "when no charge matches and the payload names no customer" do
    it "does nothing" do
      expect { described_class.new.call(event) }.not_to change(Pay::RazorbackProcessor::Charge, :count)
    end
  end
end
