class Address < ApplicationRecord
  belongs_to :addressable, polymorphic: true, optional: true
  validates :street1, :city, :state, :zipcode, :country, presence: true
  validates :addressable_type, presence: true
end
