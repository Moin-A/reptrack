class Workspace < ApplicationRecord
  # Each workspace is an Apartment tenant. `name` is the subdomain, which also
  # becomes the PostgreSQL schema name — see config/initializers/apartment.rb.
  validates :name, presence: true
end
