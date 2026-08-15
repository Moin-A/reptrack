class Workspace < ApplicationRecord
  # Each workspace is an Apartment tenant. `name` is the subdomain, which also
  # becomes the PostgreSQL schema name — see config/initializers/apartment.rb.
  attribute :name,  :string, default: :default_name
  validates :name, presence: true

  enum status: { active: 0, archived: 1, pending: 2 }

  # Users belonging to this workspace. Nullify on destroy so a deleted workspace
  # doesn't take its users' identities down with it.
  has_many :users, dependent: :nullify

  # The workspace is the billable owner: one paying customer per tenant. Users
  # belong to the workspace and carry no billing identity of their own.
  # Fake processor for now — swap default to :razorback_processor later.
  pay_customer default_payment_processor: :fake_processor

  def default_name
    # TODO: generate a real default workspace name
  end
end
