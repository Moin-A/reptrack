module Workspaces
  class ProvisionJob < ApplicationJob
    queue_as :default
    retry_on ActiveRecord::StatementInvalid, wait: :polynomially_longer, attempts: 3

    def perform(workspace)
      return if workspace.active?

      # schema_name is assigned by Workspace#after_create; make sure we see it.
      workspace.reload
      create_schema(workspace.schema_name)
      seed(workspace)

      workspace.update!(status: :active)
      notify(workspace)
    rescue StandardError
      workspace.update!(status: :failed)
      raise
    end

    private

    def create_schema(schema)
      return if ActiveRecord::Base.connection.schema_exists?(schema)
      Apartment::Tenant.create(schema)
    end

    def seed(workspace)
      Apartment::Tenant.switch(workspace.schema_name) do
        # tenant-schema writes go here
      end
    end

    def notify(workspace)
      # welcome email, Turbo broadcast, analytics
    end
  end
end
