class AccountSerializer
  include JSONAPI::Serializer
  include Normalizable

  attribute :id, :name, :email, :phone, :rating, :access, :assignee_id

  def self.normalize_records(records)
     records.map { |r| normalize(r) }
  end
end
