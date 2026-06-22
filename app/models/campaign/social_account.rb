module Campaign
  class SocialAccount < ApplicationRecord
    belongs_to :user
    has_many :publications, dependent: :destroy

    validates :platform_tag, :label, presence: true

    scope :active, -> { where(active: true) }
  end
end
