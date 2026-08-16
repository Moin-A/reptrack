module Workspaces
  class ProvisionJob < ApplicationJob
    queue_as :default
    retry_on ActiveRecord::StatementInvalid, wait: :polynomially_longer, attempts: 3

    def perform(workspace)
      return if workspace.active?

      assign_schema_name(workspace)
      create_schema(workspace.schema_name)
      seed(workspace)

      workspace.update!(status: :active)
      notify(workspace)
    rescue StandardError
      workspace.update!(status: :provisioning_failed)
      raise
    end

    private

    def assign_schema_name(workspace)
      return if workspace.schema_name.present?
      workspace.update!(schema_name: "tenant_#{workspace.id}")
    end

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
