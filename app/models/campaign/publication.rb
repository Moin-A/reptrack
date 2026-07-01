module Campaign
  class Publication < ApplicationRecord
    STATUSES = %w[ready wip published failed skipped].freeze

    belongs_to :post
    belongs_to :social_account
    has_one :user, through: :social_account

    validates :status, inclusion: { in: STATUSES }
    validates :post_id, uniqueness: { scope: :social_account_id }

    STATUSES.each do |state|
      define_method("#{state}?") { status == state }
    end
  end
end
