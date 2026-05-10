module Audit
  class Version < ApplicationRecord
    self.table_name = "audit_versions"
    belongs_to :item, polymorphic: true, optional: true
    scope :performed_by, ->(id) { where(whodunnit: id) }
  end
end
