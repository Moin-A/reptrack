class Task < ApplicationRecord
  include Audit::AuditTrail
  has_paper_trail on: [ :create, :update, :destroy ]

  validates :name, presence: { message: "must be Provided" }
  belongs_to :assignee, class_name: "User", foreign_key: :assignee_id, optional: true
  belongs_to :user
  scope :assigned_to, ->(user) { where(assignee_id: user.id) }
  scope :in_bucket, ->(bucket) { where(bucket: bucket) }
  before_save :set_due_date
  enum :bucket, %i[today tomorrow overdue as_soon_as_possible this_week next_week sometime_later]

  private

  def set_due_date
    case bucket
    when "today"
      self.due_date = Time.zone.now
    when "tomorrow"
      self.due_date = Time.zone.now + 1.day
    when "overdue"
      self.due_date = Time.zone.now - 1.day
    when "as soon as possible"
      self.due_date = Time.zone.now + 2.days
    when "this week"
      self.due_date = Time.zone.now + 7.days
    when "next week"
      self.due_date = Time.zone.now + 14.days
    when "sometime later"
      self.due_date = Time.zone.now + 30.days
    end
  end
end
