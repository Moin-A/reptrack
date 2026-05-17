class ActivitiesController < ApplicationController
  def index
    pagy, versions = pagy(filtered_users, limit: 10)
    result = { groups: ActivitiesSerializer.normalize(versions), pagination: pagy  }
    render json: result
  end

  private

  def filtered_users
    scope = Audit::Version.includes(:user, :item).all
    scope = scope.performed_by(activities_params[:by]) if activities_params[:by].present?
    scope = scope.performed_on_or_before(*resolved_date_time) if resolved_date_time.present?
    scope = scope.order(created_at: :desc)
    scope
  end

  def resolved_date_time
    Audit::Version.resolve_date_string(activities_params[:when])
  end

  def activities_params
    params.fetch(:activity, {}).permit(:by, :when, :show)
  end
end
