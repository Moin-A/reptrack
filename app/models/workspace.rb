class Workspace < ApplicationRecord
  # Each workspace is an Apartment tenant. `name` is the subdomain; `schema_name`
  # is the Postgres schema it maps to — see config/initializers/apartment.rb.
  # Created nameless at the `pending` stage (checkout); the name is collected by
  # the onboarding form when it moves to `provisioning`, so only require it then.
  validates :name, presence: true, unless: :pending?

  enum status: { active: 0, archived: 1, pending: 2, provisioning: 3, failed: 4 }

  # Users belonging to this workspace. Nullify on destroy so a deleted workspace
  # doesn't take its users' identities down with it.
  has_many :users, dependent: :nullify

  # The workspace is the billable owner: one paying customer per tenant. Users
  # belong to the workspace and carry no billing identity of their own.
  # Fake processor for now — swap default to :razorback_processor later.
  pay_customer default_payment_processor: :fake_processor

  # The schema name needs the id, so assign it right after create. Owned by the
  # workspace itself (moved out of ProvisionJob).
  after_create :assign_schema_name

  private

  def assign_schema_name
    update_column(:schema_name, "tenant_#{id}") if schema_name.blank?
  end
end
