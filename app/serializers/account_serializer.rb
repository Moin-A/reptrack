class AccountSerializer
  include JSONAPI::Serializer

  attribute :id, :name, :email, :phone, :rating, :access, :assigned_to

  def self.normalize(records)
    new(records).serializable_hash[:data].map { |r| r[:attributes] }
  end
end



