class ActivitiesController < ApplicationController
  def index
    render json: { groups: ActivitiesSerializer.normalize(filtered_users) }
  end


  private

  def filtered_users
    scope = Audit::Version.all
    scope = scope.performed_by(activities_params[:by]) if activities_params[:by].present?
    scope
  end

  def activities_params
    params.require(:activity).permit(:by, :when, :show)
  end
end
