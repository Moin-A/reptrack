module Pay
  module RazorbackProcessor
    # STI subclass of Pay::Customer -> lives in the `pay_customers` table with
    # type = "Pay::RazorbackProcessor::Customer".
    # Selected via set_payment_processor(:razorback_processor).
    class Customer < Pay::Customer
      # Maps pay_charges columns -> how to read them off a captured Razorpay payment.
      # Symbol = method to public_send on the payment; Proc = called with the payment.
      # Columns Razorpay has no equivalent for (e.g. application_fee_amount) are
      # omitted and left NULL.
      LEDGER_ATTRIBUTES = {
        processor_id:    :id,
        amount:          :amount,
        currency:        :currency,
        amount_refunded: :amount_refunded,
        metadata:        ->(captured) { captured.notes.presence }
      }.freeze

      # Pay's canonical `data` store-accessor keys + Razorpay-specific extras.
      # Nested `card` is a plain Hash, so those read via attributes.dig (nil-safe
      # when the payment method has no card).
      DATA_ATTRIBUTES = {
        payment_method_type: :method,
        brand:               ->(captured) { captured.attributes.dig("card", "network") },
        last4:               ->(captured) { captured.attributes.dig("card", "last4") },
        email:               :email,
        bank:                :bank,
        invoice_id:          :invoice_id,
        amount_captured:     :amount,
        status:              :status,
        order_id:            :order_id,
        contact:             :contact,
        acquirer_data:       :acquirer_data
      }.freeze

      # Associate with the RazorbackProcessor-typed rows in the shared pay_* tables.
      has_many :charges, dependent: :destroy, class_name: "Pay::RazorbackProcessor::Charge"
      has_many :subscriptions, dependent: :destroy, class_name: "Pay::RazorbackProcessor::Subscription"
      has_many :payment_methods, dependent: :destroy, class_name: "Pay::RazorbackProcessor::PaymentMethod"
      has_one :default_payment_method, -> { where(default: true) }, class_name: "Pay::RazorbackProcessor::PaymentMethod"

      # Razorpay has no server-side "customer object" we must create before charging,
      # so api_record just ensures we have a local record to work with.
      def api_record
        self
      end

      def update_api_record(**attributes)
        self
      end

      # charge is Phase 3 of Razorpay's flow: Phase 1 (Razorpay::Order.create) and
      # Phase 2 (client checkout) have already produced an *authorized* payment_id;
      # here we capture it (money moves) and record the result as a Pay::Charge.
      #
      #   user.payment_processor.charge(1999, payment_id: "pay_XXXX", currency: "INR")
      def charge(amount, options = {})
        payment_id = options[:payment_id]
        currency = options[:currency] || "INR"
        raise Pay::Error, "Razorpay charge requires a :payment_id" if payment_id.blank?

        # authorized (or already-captured) paymen
        # Razorpay auto-captures at checkout when the order is configured for it,
        # so the payment can already be "captured" by the time it reaches us.
        # Capturing again raises "This payment has already been captured", so only
        # capture when it hasn't happened yet; otherwise take the payment as-is.
        captured = captured_payment(razorpay_payment(payment_id), amount, currency)

        # A successful capture comes back with status "captured". Anything else
        # (failed/cancelled/authorized) means no money moved — don't record a charge.

        raise Pay::Error, "Razorpay capture did not succeed (status: #{captured.status})" unless captured.status == "captured"

        # Record the captured payment as our local ledger row: top-level pay_charges
        # columns from LEDGER_ATTRIBUTES, canonical/extra data from DATA_ATTRIBUTES.
        # find_or_initialize_by processor_id makes this idempotent — a retry for the
        # same Razorpay payment updates the existing row instead of duplicating it.
        charge = charges.find_or_initialize_by(processor_id: captured.id)
        charge.update!(
          **build_attributes(LEDGER_ATTRIBUTES, captured),
          data: build_attributes(DATA_ATTRIBUTES, captured)
        )
        charge
      rescue ::Razorpay::Error => e
        raise Pay::RazorbackProcessor::Error, e
      end

      private

      def captured_payment(razorpay_payment, amount, currency)
        if razorpay_payment.status == "captured"
          razorpay_payment
        else
          capture_payment(razorpay_payment, amount, currency)
        end
      end

      def razorpay_payment(payment_id)
        ::Razorpay::Payment.fetch(payment_id)
      end

      def capture_payment(payment, amount, currency)
        payment.capture(amount: amount, currency: currency)
      end

      # Resolves a {column => Symbol|Proc} mapping against the captured payment:
      # Symbol -> public_send on the payment, Proc -> called with the payment.
      def build_attributes(mapping, captured)
        mapping.each_with_object({}) do |(key, source), acc|
          acc[key] = source.is_a?(Proc) ? source.call(captured) : captured.public_send(source)
        end
      end

      def razorpay_payment(payment_id)
        ::Razorpay::Payment.fetch(payment_id)
      end
    end
  end
end
