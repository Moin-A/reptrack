class ApplicationController < ActionController::API
  include Pagy::Backend
  include ActionController::Cookies
  include Audit::Controller
  before_action :set_audit_whodunnit


  def index
    render json: { message: "Hello, world!" }
  end


  private

  def activities_params
  end
end
