class GroupsController < ApplicationController
    load_and_authorize_resource
    
    def index
        render json: { groups:Group.pluck(:id, :name).map { |id, name| { id: id, name: name } } }
    end

    def create
        group = Group.new(group_params)
        if group.save
        render json: GroupSerializer.normalize(group), status: :created
        else
        render json: { errors: group.errors.full_messages }, status: :unprocessable_entity
        end
    end
    
    def update
        if @group.update(group_params)
        render json: GroupSerializer.normalize(@group)
        else
        render json: { errors: @group.errors.full_messages }, status: :unprocessable_entity
        end
    end
    
    def destroy
        @group.destroy
        head :no_content
    end
    
    private
    
    def group_params
        params.fetch(:group, {}).permit(:id, :name, :description)
    end
end
