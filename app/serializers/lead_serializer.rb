class LeadSerializer
  include JSONAPI::Serializer
  include Normalizable

  attribute :id, :first_name, :last_name, :email, :alt_email, :phone, :mobile,
            :title, :company, :source, :status, :referred_by,
            :blog, :linkedin, :facebook, :twitter,
            :rating, :do_not_call, :background_info, :access,
            :assigned_to, :user_id, :created_at, :updated_at

  def self.normalize_records(records)
    records.map { |r| normalize(r) }
  end
end
