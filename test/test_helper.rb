ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Integration tests drive requests against the default host www.example.com, so the
# subdomain elevator would otherwise try to switch to a "www" tenant schema.
Apartment::Elevators::Subdomain.excluded_subdomains = %w[www api admin]

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
