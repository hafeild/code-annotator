class CreateProjectPermissions < ActiveRecord::Migration
  def change
    create_table :project_permissions do |t|
      t.references :project, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true
      t.boolean :can_author, default: false
      t.boolean :can_view, default: false
      t.boolean :can_annotate, default: false

      t.timestamps null: false
    end
    add_index :project_permissions, [:project_id, :user_id], unique: true
  end
end
