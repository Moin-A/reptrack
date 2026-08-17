# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  prepend_before_action :require_no_authentication, only: [ :new, :create ]
  prepend_before_action :allow_params_authentication!, only: :create
  prepend_before_action :verify_signed_out_user, only: :destroy
  prepend_before_action(only: [ :create, :destroy ]) { request.env["devise.skip_timeout"] = true }

  # GET /resource/sign_in
  def new
    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)
    yield resource if block_given?
    respond_with(resource, serialize_options(resource))
  end

  # POST /resource/sign_in
  def create
    self.resource = warden.authenticate(auth_options)
    if warden.message == :unconfirmed
      render json: { error: "Please confirm your email address before signing in." }, status: :forbidden
    elsif resource
       sign_in(resource_name, resource)
       render json: { message: "Signed in successfully.", user: user_payload(resource) }, status: :ok
    else
      render json: { error: "Invalid email or password." }, status: :unauthorized
    end
  end

  # DELETE /resource/sign_out
  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    if request.format.html?
      redirect_to ENV["FRONTEND_URL"].presence || "http://localhost:3001",
                  allow_other_host: true, status: :see_other
    else
      head :no_content
    end
  end

  def me
    if current_user
      render json: { user: user_payload(current_user) }, status: :ok
    else
      render json: { error: "Not authenticated" }, status: :unauthorized
    end
  end

  protected

  # Session user payload. `onboarded` tells the client whether the user has a
  # workspace yet (nil until they pay to create one); `workspace` carries its
  # id/name when present.
  def user_payload(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      onboarded: user.workspace_id?,
      workspace: user.workspace && {
        id: user.workspace.id,
        name: user.workspace.name,
        subdomain: user.workspace.subdomain,
        schema_name: user.workspace.schema_name
      }
    }
  end

  def sign_in_params
    devise_parameter_sanitizer.sanitize(:sign_in)
  end

  def serialize_options(resource)
    methods = resource_class.authentication_keys.dup
    methods = methods.keys if methods.is_a?(Hash)
    methods << :password if resource.respond_to?(:password)
    { methods: methods, only: [ :password ] }
  end

  def auth_options
    { scope: resource_name, locale: I18n.locale }
  end

  def translation_scope
    "devise.sessions"
  end

  private

  # Check if there is no signed in user before doing the sign out.
  #
  # If there is no signed in user, it will set the flash message and redirect
  # to the after_sign_out path.
  def verify_signed_out_user
    if all_signed_out?
      set_flash_message! :notice, :already_signed_out

      respond_to_on_destroy(non_navigational_status: :unauthorized)
    end
  end

  def all_signed_out?
    users = Devise.mappings.keys.map { |s| warden.user(scope: s, run_callbacks: false) }

    users.all?(&:blank?)
  end

  def respond_to_on_destroy(non_navigational_status: :no_content)
    head non_navigational_status
  end
end
