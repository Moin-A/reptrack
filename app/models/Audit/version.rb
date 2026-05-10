module Audit
  class Version < ApplicationRecord
    self.table_name = "audit_versions"
    belongs_to :item, polymorphic: true, optional: true
    scope :performed_by, ->(id) { where(whodunnit: id) }
    scope :performed_on_or_before, ->(start_date, end_date) {where("created_at > ? AND created_at < ?", start_date, end_date)}

    def self.resolve_date_string(date_string)
      case date_string
      when "today"        
        [Time.current.beginning_of_day, Time.current.end_of_day]
      when "past_2_days"  
        [2.days.ago, Time.current]
      when "past_week"    
        [1.week.ago, Time.current]
      when "past_30_days" 
        [30.days.ago, Time.current]
      end
    end
  end
end
