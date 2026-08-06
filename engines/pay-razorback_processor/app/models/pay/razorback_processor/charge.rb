module Pay
  module RazorbackProcessor
    # STI subclass of Pay::Charge -> `pay_charges` table,
    # type = "Pay::RazorbackProcessor::Charge".
    class Charge < Pay::Charge
      # Look up a charge by its Razorpay payment id (== processor_id), nil-safe on
      # blank input. Razorpay identifies every payment/refund event by payment id,
      # so this is the join between an inbound webhook and our local ledger row.
      def self.for_processor_id(payment_id)
        find_by(processor_id: payment_id) if payment_id.present?
      end

      def api_record
        self
      end

      # Refund is not implemented yet. When needed, call Razorpay's refund API
      # for this charge's processor_id and update amount_refunded (confirmed
      # asynchronously by a refund.processed webhook).
      def refund!(amount_to_refund = nil)
        raise NotImplementedError, "Razorpay refund not implemented"
      end
    end
  end
end
