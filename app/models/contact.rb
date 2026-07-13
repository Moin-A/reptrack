class Contact < ApplicationRecord
  include Ransackable

  belongs_to :lead
  belongs_to :user
  belongs_to :assignee, class_name: "User", foreign_key: :assignee_id
  belongs_to :account, optional: true

  with_permission

  # Attributes carried over verbatim from the lead being converted. The contact
  # has no form of its own — the lead *is* the person — so each of these is
  # copied rather than re-entered.
  COPIED_FROM_LEAD = %w[
    first_name last_name title source email alt_email phone mobile
    blog linkedin facebook twitter do_not_call background_info access
  ].freeze

  def self.create_for(lead, account, params = {})
    params = (params || {}).to_h.symbolize_keys

    attributes = COPIED_FROM_LEAD.index_with { |name| lead.public_send(name) }
    attributes.merge!(
      lead:        lead,
      account:     account,
      user:        lead.user,
      assignee_id: params[:assignee_id] || lead.assignee_id
    )

    contact = Contact.new(attributes)

    if lead.access!= "Lead" || lead.nil?
        contact.save!
    else
        save_with_model_permissions(lead)
    end

    contact
  end
end
