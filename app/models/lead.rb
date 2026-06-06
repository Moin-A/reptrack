class Lead < ApplicationRecord
  belongs_to :user,     optional: true
  belongs_to :assignee, class_name: "User", foreign_key: :assignee_id, optional: true
  has_many   :tasks,    as: :asset, dependent: :destroy
  has_one   :business_address, -> { where(addressable_type: "Business") }, class_name: "Address", as: :addressable, dependent: :destroy
  has_one   :contact, dependent: :destroy

  accepts_nested_attributes_for :business_address, allow_destroy: true

  validates :first_name, format: { with: /\A[A-Za-z\s]+\z/, message: "the name format is not valid" }
  validates :last_name, format: { with: /\A[A-Za-z\s]+\z/, message: "the name format is not valid" }
  attribute :first_name, :string, default: ""
  attribute :last_name, :string, default: ""
end
