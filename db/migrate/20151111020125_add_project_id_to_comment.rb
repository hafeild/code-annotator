class AddProjectIdToComment < ActiveRecord::Migration[4.2]
  def change
    add_column :comments, :project_id, :integer, index: true, foreign_key: true
  end
end
