class ActivitiesController < ApplicationController
  def index
    result = { groups: ActivitiesSerializer.normalize(filtered_users) }
    Rails.logger.info "-----| ActivitiesController#index response: #{result.to_json} |-----"
    render json: result
  end


  private

  def filtered_users
    scope = Audit::Version.all
    scope = scope.performed_by(activities_params[:by]) if activities_params[:by].present?
    scope = scope.performed_on_or_before(*resolved_date_time) if resolved_date_time.present?
    scope
  end

  def resolved_date_time
    Audit::Version.resolve_date_string(activities_params[:when])
  end

  def activities_params
    params.fetch(:activity, {}).permit(:by, :when, :show)
  end
end
