module Campaign
  class Post < ApplicationRecord
    belongs_to :user
    has_many :publications, dependent: :destroy
    has_many :social_accounts, through: :publications

    validates :content, presence: true
  end
end
