class RemoveUserForeignKeysFromTenantTables < ActiveRecord::Migration[7.2]
  TABLES = %i[
    accounts
    contacts
    leads
    opportunities
    permissions
    role_users
    tasks
    versions
    posts
    social_accounts
  ].freeze

  def up
    Apartment.tenant_names.each do |tenant|
      Apartment::Tenant.switch(tenant) do
        TABLES.each do |table|
          next unless table_exists?(table)

          foreign_keys(table).each do |fk|
            if fk.column.to_s == "user_id"
              remove_foreign_key table, name: fk.name
            end
          end
        end
      end
    end
  end

  def down
    # Don't recreate these automatically unless you explicitly want
    # the old tenant.users foreign keys back.
  end
end