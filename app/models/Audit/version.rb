module Audit
  class Version < ApplicationRecord
    include VersionConcern
    belongs_to :user, class_name: "User", foreign_key: "whodunnit", optional: true
    self.table_name = "audit_versions"
    scope :performed_by, ->(id) { where(whodunnit: id) }
    scope :performed_on_or_before, ->(start_date, end_date) { where("created_at > ? AND created_at < ?", start_date, end_date) }

    def self.resolve_date_string(date_string)
      case date_string.to_s.strip.gsub(" ", "_").downcase
      when "today"        then [ Time.current.beginning_of_day, Time.current.end_of_day ]
      when "past_2_days"  then [ 2.days.ago, Time.current ]
      when "past_week"    then [ 1.week.ago, Time.current ]
      when "past_30_days" then [ 30.days.ago, Time.current ]
      end
    end

    def self.visible_to(user)
      all.select do |version|
        item = version.item || version.reify
        item.user_id == user.id || item.assignee_id == user.id || user.admin? || version.whodunnit.to_i == user.id
      end
    end
  end
end
