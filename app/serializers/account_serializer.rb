class AccountSerializer
  include JSONAPI::Serializer
  include Normalizable

  attribute :id, :name, :email, :phone, :rating, :access, :assignee_id, :shipping_address, :billing_address

  def self.normalize_records(records)
     records.map { |r| normalize(r) }
  end

  def shipping_address
    object.shipping_address
  end

  def billing_address
    object.billing_address
  end
end
