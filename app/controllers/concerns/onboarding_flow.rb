module OnboardingFlow
  extend ActiveSupport::Concern

  STEP_PATHS = {
    nil              => :billing_checkout_path,
    "pending"        => :edit_billing_workspace_path,
    "paid"           => :edit_billing_workspace_path,
    "provisioning"   => :billing_provisioning_path,
    "active"         => :dashboard_path
  }.freeze

  included do
    before_action :enforce_step
  end

  class_methods do
    def onboarding_step(status) = @onboarding_step = status
    def required_step = @onboarding_step
  end

  private

  def enforce_step
    current = current_user.workspace&.status
    return if current == self.class.required_step

    target = send(STEP_PATHS.fetch(current))
    # Some statuses share a destination (nil and "pending" both route to
    # checkout), but a controller enforces a single required_step. Without this
    # guard, a status that maps to the current page yet isn't the required_step
    # redirects to the page it's already on — an infinite loop.
    return if target == request.path

    redirect_to target
  end
end
