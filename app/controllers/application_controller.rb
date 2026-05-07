class ApplicationController < ActionController::API
  include ActionController::Cookies
  include Audit::Controller
  before_action :set_audit_whodunnit
end
