class AddDirectoryIdToProjectFile < ActiveRecord::Migration[4.2]
  def change
    add_column :project_files, :directory_id, :integer
    add_index :project_files, :directory_id
  end
end
