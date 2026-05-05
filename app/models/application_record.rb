class ApplicationRecord < ActiveRecord::Base
  include Audit::AuditTrail
  primary_abstract_class
end
