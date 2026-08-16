class WorkspacesController < BrowserController
  layout "application"
  protect_from_forgery with: :exception
  before_action :authenticate_user!

  def edit
    @workspace = current_user.workspace
  end

  def update
    @workspace = current_user.workspace
    if @workspace.update(workspace_params.merge(status: :provisioning))
      Workspaces::ProvisionJob.perform_later(@workspace)
      redirect_to billing_workspace_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def workspace_params
    params.require(:workspace).permit(:name, :subdomain)
  end
end
