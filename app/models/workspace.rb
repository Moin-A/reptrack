class Workspace < ApplicationRecord
  # Each workspace is an Apartment tenant. `name` is the subdomain, which also
  # becomes the PostgreSQL schema name — see config/initializers/apartment.rb.
  validates :name, presence: true

  # The workspace is the billable owner: one paying customer per tenant. Users
  # belong to the workspace and carry no billing identity of their own.
  # Fake processor for now — swap default to :razorback_processor later.
  pay_customer default_payment_processor: :fake_processor
end
