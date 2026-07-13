class ApplicationController < ActionController::API
  include Pagy::Backend
  include ActionController::Cookies
  include Audit::Controller
  include Sortable
  before_action :set_audit_whodunnit


  def index
    render json: { message: "Hello, world!" }
  end

  rescue_from ActiveRecord::StatementInvalid, with: :handle_statement_invalid
  rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found

  private

  def activities_params
  end

  def handle_statement_invalid(exception)
    raise exception unless exception.cause.is_a?(PG::CheckViolation)
    render json: { errors: [ "Platform not supported — choose Facebook, Mastodon, X, or Instagram." ] },
             status: :unprocessable_entity
  end

  def handle_record_not_found(exception)
    render json: { errors: [ "#{exception.model} not found" ] }, status: :not_found
  end
end
