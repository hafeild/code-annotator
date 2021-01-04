class AddContentsToFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :project_files, :content, :text
    add_column :project_files, :is_directory, :boolean
  end
end
