require "rails_helper"

# Demonstrates how the Pay gem works using its built-in *fake_processor*.
# The fake processor implements the same interface as Stripe/Braintree/etc.
# (see Pay::FakeProcessor::Customer) but generates fake ids instead of calling
# a real payment API — so these specs run offline and are the reference for how
# a future Pay::Razorpay processor would behave.
#
# Workspace is the billable owner: `pay_customer default_payment_processor:
# :fake_processor`, so `workspace.payment_processor` lazily builds a
# Pay::FakeProcessor::Customer.
RSpec.describe "Pay gem integration (fake processor)", type: :model do
  let(:workspace) { create(:workspace) }

  it "gives the workspace a fake payment processor and can charge it" do
    processor = workspace.payment_processor

    expect(processor).to be_a(Pay::FakeProcessor::Customer)
    expect(processor.processor).to eq("fake_processor")

    # Amounts are in cents. Returns a persisted Pay::Charge.
    charge = processor.charge(19_99)

    expect(charge).to be_a(Pay::Charge)
    expect(charge.amount).to eq(1999)
    expect(charge.data["brand"]).to eq("Fake")
    expect(workspace.charges).to include(charge)
  end

  it "creates an active subscription" do
    subscription = workspace.payment_processor.subscribe(name: "default", plan: "monthly")

    expect(subscription).to be_a(Pay::Subscription)
    expect(subscription.status).to eq("active")
    expect(subscription.processor_plan).to eq("monthly")
    expect(subscription.active?).to be(true)
    expect(workspace.payment_processor.subscribed?(name: "default")).to be(true)
  end
end
