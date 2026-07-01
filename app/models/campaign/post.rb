module Campaign
  class Post < ApplicationRecord
    # Organic post vs paid ad. Ads publish through platforms' Marketing APIs
    # (a separate path) — the kind is recorded now; ad publishing comes later.
    enum :kind, { post: "post", ad: "ad" }

    belongs_to :user
    has_many :publications, dependent: :destroy
    has_many :social_accounts, through: :publications

    # Image/video uploads (text overlay compositing is a later, server-side step).
    has_many_attached :media

    validates :content, presence: true
  end
end
