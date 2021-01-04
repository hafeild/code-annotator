class AddFilenameUniquenessIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :project_files, [:project_id, :name, :directory_id], unique: true
  end
end
