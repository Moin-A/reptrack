class SubscriptionsController < ApplicationController
  before_action :authenticate_user!

  # POST /subscriptions
  #
  # Spike: no model or persistence yet. The pry is here so the browser's real
  # subscription payload can be inspected before the schema is designed around
  # it. Useful locals: `current_user`, `subscription_params`, `Apartment::Tenant.current`.
  def create
    head :created
  end

  def token
    token = JwtTokenService.new(current_user).encode({ user_id: current_user.id, exp: Time.now.to_i + 300 })
    cookies[:push_token] = token
    head :ok
  end

  private

  def subscription_params
    params.require(:subscription).permit(:endpoint, keys: [ :p256dh, :auth ])
  end
end
