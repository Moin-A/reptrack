class AddWorkspaceToUsers < ActiveRecord::Migration[7.2]
  # Users are public (auth/identity), separated per workspace by this reference.
  # Nullable because a user signs up before paying to create their workspace.
  # No DB foreign key: keep the public User decoupled from the tenant registry.
  def change
    add_reference :users, :workspace, null: true, index: true
  end
end
