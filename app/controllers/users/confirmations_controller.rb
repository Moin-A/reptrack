# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if resource.errors.empty?
      redirect_to ENV.fetch("FRONTEND_URL", "http://localhost:3000"), allow_other_host: true
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
