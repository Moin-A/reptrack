class Lead < ApplicationRecord
  belongs_to :user,     optional: true
  belongs_to :assignee, class_name: "User", foreign_key: :assignee_id, optional: true
  has_many   :tasks,    as: :asset, dependent: :destroy
end
