class PostSerializer
  extend Rails.application.routes.url_helpers
  include JSONAPI::Serializer
  include Normalizable

  attributes :id, :content, :kind, :status, :url, :media, :publications

  attribute :media do |object|
    object.media.map { |attachment| {
      id: attachment.id,
      filename: attachment.filename.to_s,
      url: Rails.application.routes.url_helpers.rails_blob_url(attachment)
    }}
  end

  def self.normalize_records(records)
     records.map { |r| normalize(r) }
  end

  attribute :publications do |object|
    object.publications.map { |pub| {
      id: pub.id,
      status: pub.status
    }}
  end
end
