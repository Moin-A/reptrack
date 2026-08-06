require "rails_helper"

RSpec.describe Pay::RazorbackProcessor::Charge, type: :model do
  describe ".for_processor_id" do
    let(:workspace)       { create(:workspace) }
    let(:customer)   { workspace.set_payment_processor(:razorback_processor) }
    let(:payment_id) { "pay_123" }
    let!(:charge)    { customer.charges.create!(processor_id: payment_id, amount: 1, data: {}) }

    it "returns the charge with the matching Razorpay payment id" do
      expect(described_class.for_processor_id(payment_id)).to eq(charge)
    end

    it "returns nil for an unknown payment id" do
      expect(described_class.for_processor_id("pay_missing")).to be_nil
    end

    it "short-circuits on a blank id without querying" do
      expect(described_class).not_to receive(:find_by)
      expect(described_class.for_processor_id("")).to be_nil
      expect(described_class.for_processor_id(nil)).to be_nil
    end
  end
end
