module Campaign
  class SocialAccount < ApplicationRecord
    include Reptrack::Preferences::Persistable

    belongs_to :user
    has_many :publications, dependent: :destroy

    # Access tokens at rest are ciphertext (keys in ENV; see the
    # active_record_encryption initializer).
    encrypts :credentials

    validates :platform_tag, :label, presence: true

    scope :active, -> { where(active: true) }
  end
end
