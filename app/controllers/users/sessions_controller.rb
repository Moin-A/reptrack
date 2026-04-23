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
       render json: { message: "Signed in successfully.", user: { id: resource.id, email: resource.email } }, status: :ok
    else
      render json: { error: "Invalid email or password." }, status: :unauthorized
    end
  end

  # DELETE /resource/sign_out
  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message! :notice, :signed_out if signed_out
    yield if block_given?
    respond_to_on_destroy(non_navigational_status: :no_content)
  end

  def me
    if current_user
      render json: { user: { id: current_user.id, email: current_user.email } }, status: :ok
    else
      render json: { error: "Not authenticated" }, status: :unauthorized
    end
  end

  protected

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
