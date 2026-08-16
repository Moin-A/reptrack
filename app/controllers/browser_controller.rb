# app/controllers/browser_controller.rb
class BrowserController < ActionController::Base
  layout "application"
  protect_from_forgery with: :exception
  before_action :authenticate_user!
end
