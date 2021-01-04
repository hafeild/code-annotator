class AddEmailFieldToPermissions < ActiveRecord::Migration[4.2]
  def change
    add_column :project_permissions, :user_email, :string
    add_index :project_permissions, [:project_id, :user_email], unique: true
  end
end
