class Account < ApplicationRecord
   include Reptrack::Permission
   has_one :billing_address, -> { where(address_type: "billing") }, as: :addressable, class_name: "Address"
   has_one :shipping_address, -> { where(address_type: "shipping") }, as: :addressable, class_name: "Address"
   has_many :addresses, as: :addressable, class_name: "Address"


   accepts_nested_attributes_for :shipping_address, allow_destroy: true
   accepts_nested_attributes_for :billing_address, allow_destroy: true
   validates :email, format: { with: /\A[^\s@]+@[^\s@]+\z/, message: "the email format is not valid" }
   attribute :access, :string, default: "Private"
   belongs_to :user, optional: true
   belongs_to :assignee, class_name: "User", foreign_key: "assignee_id", optional: true
   belongs_to :user, class_name: "User", foreign_key: "user_id", optional: true

   with_permission

   # Own columns we don't export as-is: foreign keys (shown as names instead)
   # and timestamps (relabeled below).
   EXCLUDED_COLUMNS = %w[user_id assignee_id created_at updated_at].freeze

   # Cross-model / relabeled columns that can't be derived from the schema:
   # association names and the nested billing/shipping address fields.
   CUSTOM_COLUMNS = [
     "User", "Assigned To", "Date Created", "Date Updated",
     "Billing Street1", "Billing Street2", "Billing City", "Billing State", "Billing Zipcode", "Billing Country",
     "Shipping Street1", "Shipping Street2", "Shipping City", "Shipping State", "Shipping Zipcode", "Shipping Country"
   ].freeze

   # XLS column labels: the model's own scalar columns (titleized) followed by
   # the custom cross-model columns.
   def self.model_headers
     (column_names - EXCLUDED_COLUMNS).map(&:titleize) + CUSTOM_COLUMNS
   end
end
