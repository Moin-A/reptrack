class AddWhodunnitIndexToAuditVersions < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    change_column_null :audit_versions, :whodunnit, false
    add_index :audit_versions, :whodunnit,
              algorithm: :concurrently,
              name: "audit_version_whodunnit_index"
  end
end
