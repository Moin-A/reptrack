class Lead < ApplicationRecord
  belongs_to :user,     optional: true
  belongs_to :assignee, class_name: "User", foreign_key: :assignee_id, optional: true
  has_many   :tasks,    as: :asset, dependent: :destroy

  validates :first_name, format: { with: /\A[A-Za-z\s]+\z/, message: "the name format is not valid" }
  validates :last_name, format: { with: /\A[A-Za-z\s]+\z/, message: "the name format is not valid" }
  attribute :first_name, :string, default: ""
  attribute :last_name, :string, default: ""
end
