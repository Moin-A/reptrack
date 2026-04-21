# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  protected

  def after_confirmation_path_for(resource_name, resource)
    ENV.fetch("FRONTEND_URL", "http://localhost:3000")
  end
end
