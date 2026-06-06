class Contact < ApplicationRecord
  belongs_to :lead
  belongs_to :user
  belongs_to :assignee, class_name: "User", foreign_key: :assignee_id
end
