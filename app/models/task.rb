class Task < ApplicationRecord
  validates :name, presence: { message: "must be Provided" }
  belongs_to :assignee, class_name: "User", foreign_key: :assignee_id, optional: true
  belongs_to :user
  scope :assigned_to, ->(user) { where(assignee_id: user.id) }
  scope :in_bucket, ->(bucket) { where(bucket: bucket) }
  before_update :set_due_date
  enum :bucket, %i[today tomorrow overdue as_soon_as_possible this_week next_week sometime_later]

  private

  def set_due_date
    case bucket
    when "today"
    when "tomorrow"
    when "overdue"
    when "as soon as possible"
    when "this week"
    when "next week"
    when "sometime later"
    end
  end
end
