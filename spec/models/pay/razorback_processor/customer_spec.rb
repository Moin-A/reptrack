require "rails_helper"

# Specs for the custom Pay processor Pay::RazorbackProcessor::Customer
# (STI subclass of Pay::Customer, backed by Razorpay).
#
# Covers: processor resolution / STI identity, the missing-payment_id guard,
# the capture happy-path (records a Pay::Charge), and the two failure paths —
# the Razorpay SDK raising on capture, and capture returning a non-captured
# payment without raising.
RSpec.describe Pay::RazorbackProcessor::Customer, type: :model do
  let(:workspace) { create(:workspace) }

  describe "processor resolution / STI" do
    subject(:customer) { workspace.set_payment_processor(:razorback_processor) }

    it "resolves :razorback_processor to this class" do
      expect(customer).to be_a(described_class)
    end

    it "is an STI row in pay_customers" do
      # Schema-qualified ("public.pay_customers") because Pay::Customer is an
      # Apartment excluded_model — it lives in the shared public schema.
      expect(described_class.table_name).to end_with("pay_customers")
      expect(customer.type).to eq("Pay::RazorbackProcessor::Customer")
      expect(customer.processor).to eq("razorback_processor")
    end

    it "descends from the Pay::Customer STI base" do
      expect(described_class.ancestors).to include(Pay::Customer)
    end
  end

  describe "#charge" do
    subject(:customer) { workspace.set_payment_processor(:razorback_processor) }
    let(:response) { show_response("payment_processor/customer", filename: "success") }

    it "raises when no payment_id is given (capture needs a completed checkout)" do
      expect { customer.charge(1999) }.to raise_error(Pay::Error, /payment_id/)
    end

    it "captures the payment_id via the Razorpay SDK and records a Pay::Charge" do
      payment  = stub_api_response(::Razorpay::Payment, :fetch, response)
      stub_api_response(payment, :capture, response)

      charge = customer.charge(response["amount"], payment_id: response["id"], currency: response["currency"])

      expect(charge).to be_a(Pay::RazorbackProcessor::Charge)
      expect(charge.amount).to eq(9900)
      expect(charge.processor_id).to eq("pay_L0nSsccovt6zyp")
    end

    it "is idempotent — a retry for the same payment_id updates the row, not duplicates it" do
      payment = stub_api_response(::Razorpay::Payment, :fetch, response)
      stub_api_response(payment, :capture, response)

      first  = customer.charge(response["amount"], payment_id: response["id"], currency: response["currency"])
      second = customer.charge(response["amount"], payment_id: response["id"], currency: response["currency"])

      expect(second.id).to eq(first.id)
      expect(customer.charges.where(processor_id: response["id"]).count).to eq(1)
    end

    context "when the capture fails" do
      # failure.json is a failed/cancelled payment (status: "failed").
      let(:response) { show_response("payment_processor/customer", filename: "failure") }

      def charge!
        customer.charge(response["amount"], payment_id: response["id"], currency: response["currency"])
      end

      context "and the Razorpay SDK raises" do
        let(:razorpay_error) { ::Razorpay::BadRequestError.new(response["error_code"], 400) }

        before do
          payment = stub_api_response(::Razorpay::Payment, :fetch, response)
          allow(payment).to receive(:capture).and_raise(razorpay_error)
        end

        it "wraps the SDK error as Pay::RazorbackProcessor::Error" do
          expect { charge! }.to raise_error(Pay::RazorbackProcessor::Error)
        end

        it "keeps the original Razorpay error as the cause" do
          expect { charge! }.to raise_error(Pay::RazorbackProcessor::Error) { |e| expect(e.cause).to eq(razorpay_error) }
        end

        it "does not persist a Pay::Charge" do
          expect { charge! rescue Pay::RazorbackProcessor::Error }.not_to change(Pay::RazorbackProcessor::Charge, :count)
        end
      end

      context "and capture returns a non-captured payment (no SDK error)" do
        before do
          payment = stub_api_response(::Razorpay::Payment, :fetch, response)
          stub_api_response(payment, :capture, response) # status: "failed"
        end

        it "raises Pay::Error because no money moved" do
          expect { charge! }.to raise_error(Pay::Error, /did not succeed/)
        end

        it "does not persist a Pay::Charge" do
          expect { charge! rescue Pay::Error }.not_to change(Pay::RazorbackProcessor::Charge, :count)
        end
      end
    end
  end
end
