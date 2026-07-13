class OpportunitySerializer
  include JSONAPI::Serializer
  include Normalizable

  attribute :id, :name, :stage, :closes_on, :probability, :amount, :discount,
            :access, :account_id, :lead_id, :assignee_id

  def self.normalize_records(records)
    records.map { |r| normalize(r) }
  end
end
