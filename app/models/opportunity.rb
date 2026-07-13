class Opportunity < ApplicationRecord
  include Ransackable

  belongs_to :account,  optional: true
  belongs_to :lead,     optional: true
  belongs_to :user,     optional: true
  belongs_to :assignee, class_name: "User", foreign_key: :assignee_id, optional: true

  validates :name, presence: true
  with_permission
  # Builds the opportunity for a lead being converted. Unlike the contact, an
  # opportunity is optional: the form only creates one when a name was entered.
  # Returns an unsaved, unnamed Opportunity when there is nothing to create, so
  # callers can treat the result uniformly (it simply has no id).
  def self.create_for(lead, account, params = {})
    opportunity = Opportunity.new(params)

    opportunity.account = account
    opportunity.lead = lead

    if opportunity.access!= "Lead" || lead.nil?
       opportunity.save!
    else
       save_with_model_permissions(lead)
    end


    opportunity
  end
end
