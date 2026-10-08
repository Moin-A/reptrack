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
  rescue_from CanCan::AccessDenied, with: :handle_access_denied

  private

  # Lets lograge (config/initializers/lograge.rb) include who made the
  # request and its request id in the one-line JSON log.
  def append_info_to_payload(payload)
    super
    payload[:user_id] = current_user&.id
    payload[:request_id] = request.request_id
  end

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

  # Was unhandled — every authorization failure (including a plain
  # unauthenticated request, since current_user being nil grants zero
  # abilities) crashed as a raw 500 instead of a clean 401/403.
  def handle_access_denied(exception)
    status = current_user ? :forbidden : :unauthorized
    render json: { errors: [ exception.message ] }, status: status
  end
end
