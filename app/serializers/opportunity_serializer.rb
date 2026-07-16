class OpportunitySerializer
  include JSONAPI::Serializer
  include Normalizable

  attribute :id, :name, :stage, :closes_on, :probability, :amount, :discount,
            :access, :account_id, :lead_id, :assignee_id, :user_id, :created_at

  # The panel shows the account and owner by name, not id.
  attribute :account do |object|
    object.account&.name
  end

  attribute :user do |object|
    object.user&.name
  end

  attribute :assignee do |object|
    object.assignee&.name
  end

  # Amount is a decimal; the frontend does arithmetic on it (pipeline totals,
  # weighted value), so send it as a number rather than a string.
  attribute :amount do |object|
    object.amount.to_f
  end

  attribute :probability do |object|
    object.probability.to_i
  end

  def self.normalize_records(records)
    records.map { |r| normalize(r) }
  end
end
