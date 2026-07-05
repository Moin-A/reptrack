class SocialAccountsSerializer
  include JSONAPI::Serializer
  include Normalizable
  attributes :id, :platform_tag, :label, :active, :connected_at

  def self.normalize_records(records)
     records.map { |r| normalize(r) }
  end

  attribute :connected_at do |object|
    object.credentials_renewed_at
  end
end
