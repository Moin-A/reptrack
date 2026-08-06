require_relative "lib/pay/razorback_processor/version"

Gem::Specification.new do |spec|
  spec.name        = "pay-razorback_processor"
  spec.version     = Pay::RazorbackProcessor::VERSION
  spec.authors     = ["Reptrack"]
  spec.summary     = "Razorpay (razorback) payment processor for the Pay gem"
  spec.description  = "A Pay processor backing Pay with Razorpay: capture-based charges and webhook-driven charge syncing."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.files = Dir["{app,config,lib}/**/*", "MIT-LICENSE", "README.md"].select { |f| File.file?(f) }

  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "pay", "~> 8.3"
  spec.add_dependency "razorpay", "~> 3.0"
end
