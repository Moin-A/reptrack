class AllowNullWorkspaceName < ActiveRecord::Migration[7.2]
  # Workspaces are created nameless at the `pending` stage (checkout); the name is
  # collected later by the onboarding form. Drop the NOT NULL constraint so the
  # pending row can be inserted (model validates presence once past pending).
  def change
    change_column_null :workspaces, :name, true
  end
end
