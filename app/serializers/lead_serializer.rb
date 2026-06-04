class LeadSerializer
  include JSONAPI::Serializer
  include Normalizable

  attribute :id, :first_name, :last_name, :email, :alt_email, :phone, :mobile,
            :title, :company, :source, :status, :referred_by,
            :blog, :linkedin, :facebook, :twitter,
            :rating, :do_not_call, :background_info, :access,
            :assignee, :user_id, :created_at, :updated_at

  attribute :assignee do |object|
    object.assignee && { id: object.assignee.id, name: object.assignee.name, email: object.assignee.email }
  end

  def self.normalize_records(records)
    records.map { |r| normalize(r) }
  end

  attribute :whodunnit do |object|
    object.user && { id: object.user.id, name: object.user.name, email: object.user.email }
  end

end
