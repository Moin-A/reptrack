class Task < ApplicationRecord
  include Audit::AuditTrail
  has_paper_trail on: [ :create, :update, :destroy ]

  validates :name, presence: { message: "must be Provided" }
  belongs_to :asset , polymorphic: true, optional: true
  belongs_to :assignee, class_name: "User", foreign_key: :assignee_id, optional: true
  belongs_to :user
  scope :assigned_to, ->(user) { where(assignee_id: user.id) }
  scope :in_bucket, ->(bucket) { where(bucket: bucket) }
  before_save :set_due_date
  enum :bucket, %i[today tomorrow overdue as_soon_as_possible this_week next_week sometime_later]

  private

def set_due_date
  now = Time.zone.now
  self.due_date =
    case bucket
    when "today"
      now
    when "tomorrow"
      now.tomorrow.end_of_day
    when "overdue"
      now.yesterday
    when "as_soon_as_possible"
      now + 2.days
    when "this_week"
      now.end_of_week
    when "next_week"
      now.next_week.end_of_week
    when "sometime_later"
      now + 30.days
    end
end
end
