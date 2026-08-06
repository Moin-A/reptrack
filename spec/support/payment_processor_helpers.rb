module PaymentProcessorHelpers
   def show_response(path, **options)
    filename = "#{options[:filename] || "details"}.json"
    path = [ path, filename ].join("/")


    JSON.parse file_fixture(path).read
   end

   # Stubs an SDK call and returns the entity it will answer with.
   #
   # Works for class methods (pass the class) and instance methods (pass the
   # instance) — the stub always goes on whatever object you pass:
   #
   #   response = show_response("payment_processor/customer", filename: "success")
   #   payment  = stub_api_response(::Razorpay::Payment, :fetch, response)  # class method
   #   captured = stub_api_response(payment, :capture, response)           # instance method
   #
   # The response hash is wrapped in a fresh SDK entity so fields read via
   # method access (entity.amount) exactly like production — which also
   # mirrors capture returning a NEW entity built from the server response.
   def stub_api_response(api, method, response)
    klass = api.is_a?(Class) ? api : api.class
    entity = klass.new(response)
    allow(api).to receive(method).and_return(entity)
    entity
   end
end
