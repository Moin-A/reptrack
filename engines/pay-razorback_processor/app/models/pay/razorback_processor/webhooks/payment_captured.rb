module Pay
  module RazorbackProcessor
    module Webhooks
      # Handles Razorpay `payment.captured`: syncs the local Pay::Charge to the
      # authoritative payment entity so views render current state. Idempotent —
      # re-delivered events just re-apply the same values.
      #
      # Normally Customer#charge already recorded the row, so we just find it by
      # processor_id and update. If it's missing (the reconciliation backstop:
      # capture succeeded but the local write didn't), we recover it — but only
      # if the order notes name a customer that exists, since a charge must
      # belong to one. Otherwise there's nothing to attach it to, so we drop it.
      class PaymentCaptured
        def call(event)
          entity = event.dig("payload", "payment", "entity")
          return if entity.blank?

          charge = Charge.for_processor_id(entity["id"]) || recover_charge(entity)
          return if charge.nil?

          charge.update!(
            amount: entity["amount"],
            amount_refunded: entity["amount_refunded"],
            data: charge.data.to_h.merge("status" => entity["status"])
          )
        end

        private

        def recover_charge(entity)
          customer_id = entity.dig("notes", "pay_customer_id")
          customer = Pay::RazorbackProcessor::Customer.find_by(id: customer_id)
          customer&.charges&.find_or_initialize_by(processor_id: entity["id"])
        end
      end
    end
  end
end
