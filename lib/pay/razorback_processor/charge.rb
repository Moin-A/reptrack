module Pay
  module RazorbackProcessor
    # STI subclass of Pay::Charge -> `pay_charges` table,
    # type = "Pay::RazorbackProcessor::Charge".
    class Charge < Pay::Charge
      def api_record
        self
      end

      # TODO(you): call Razorpay's refund API for this charge's processor_id,
      # then update amount_refunded. See Pay::FakeProcessor::Charge#refund!.
      def refund!(amount_to_refund = nil)
        raise NotImplementedError, "Implement Razorpay refund via ::Razorpay::Payment/Refund"
      end
    end
  end
end
