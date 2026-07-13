class Lead < ApplicationRecord
  include Ransackable
  belongs_to :user,     optional: true
  belongs_to :assignee, class_name: "User", foreign_key: :assignee_id, optional: true
  has_many   :tasks,    as: :asset, dependent: :destroy
  has_one   :business_address, -> { where(address_type: "Business") }, class_name: "Address", as: :addressable, dependent: :destroy
  has_one   :contact, dependent: :destroy

  accepts_nested_attributes_for :business_address, allow_destroy: true

  validates :first_name, format: { with: /\A[A-Za-z\s]+\z/, message: "the name format is not valid" }
  validates :last_name, format: { with: /\A[A-Za-z\s]+\z/, message: "the name format is not valid" }
  attribute :first_name, :string, default: ""
  attribute :last_name, :string, default: ""

  with_permission
  # Promotes this lead into an Account + Contact (+ an optional Opportunity) and
  # marks it converted. The account is resolved first because the other two hang
  # off it. Everything happens in one transaction: a validation failure anywhere
  # leaves the lead unconverted and writes nothing.
  #
  # Returns [account, opportunity, contact] so the caller can inspect errors.
  def promote(params = {})
    transaction do
      account     = Account.create_or_select_for(self, params[:account])
      opportunity = Opportunity.create_for(self, account, params[:opportunity])
      contact     = Contact.create_for(self, account, params)


      update!(status: "converted")

      [ account, opportunity, contact ]
    end
  end
end
