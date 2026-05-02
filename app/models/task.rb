class Task < ApplicationRecord
  validates :name, presence: {message: "must be Provided"}
  belongs_to :assignee, class_name: "User", foreign_key: :assignee_id
  scope :assigned_to, ->(user) { where(assignee_id: user.id) }
end
