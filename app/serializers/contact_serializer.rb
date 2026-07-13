class ContactSerializer
  include JSONAPI::Serializer
  include Normalizable

  attribute :id, :first_name, :last_name, :title, :email, :alt_email,
            :phone, :mobile, :source, :access, :lead_id, :account_id, :assignee_id

  def self.normalize_records(records)
    records.map { |r| normalize(r) }
  end
end
