class ApplicationController < ActionController::API
  include ActionController::Cookies
  include Audit::Controller
  before_action :set_audit_whodunnit


  def index
    binding.pry
    render json: { message: "Hello, world!" }
  end


  private

  def activities_params
  end
end
