class ChangeColumnTypeOfAuditVersionTable < ActiveRecord::Migration[7.2]
  def up
    change_column :audit_versions, :object, 'jsonb USING object::jsonb'
  end

  def down
    change_column :audit_versions, :object, 'text USING object::text'
  end
end
