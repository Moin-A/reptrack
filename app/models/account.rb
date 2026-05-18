class Account < ApplicationRecord
   has_one :billing_address, -> { where(address_type: "billing") }, as: :addressable, class_name: "Address"
   has_one :shipping_address, -> { where(address_type: "shipping") }, as: :addressable, class_name: "Address"
   has_many :addresses, as: :addressable, class_name: "Address"
   accepts_nested_attributes_for :shipping_address, allow_destroy: true
   accepts_nested_attributes_for :billing_address, allow_destroy: true
   validates :email, format: { with: /\A[^\s@]+@[^\s@]+\z/, message: "the email format is not valid" }
end
