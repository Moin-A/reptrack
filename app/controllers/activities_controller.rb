class ActivitiesController < ApplicationController

  def index
    render json: {groups: ActivitiesSerializer.normalize }
  end


  private

  def activities_params
  end
end
