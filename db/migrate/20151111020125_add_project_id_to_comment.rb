class AddProjectIdToComment < ActiveRecord::Migration
  def change
    add_column :comments, :project_id, :integer, index: true, foreign_key: true
  end
end
