class ActivitiesSerializer
  include JSONAPI::Serializer
  attribute :id, :whodunnit, :event, :item_id, :entity, :entity_type

  def self.normalize
    new(Audit::Version.all).serializable_hash[:data].map{|r| r[:attributes]}
  end

  attribute :whodunnit do |task|
    User.find(task.whodunnit)
  end

  attribute :entity_type do |task|
    task.item_type
  end

  attribute :entity do |task|
    task.item
  end
  
end