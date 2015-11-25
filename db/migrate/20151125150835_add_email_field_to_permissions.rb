class AddEmailFieldToPermissions < ActiveRecord::Migration
  def change
    add_column :project_permissions, :user_email, :string
    add_index :project_permissions, [:project_id, :user_email], unique: true
  end
end
