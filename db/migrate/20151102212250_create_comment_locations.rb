class CreateCommentLocations < ActiveRecord::Migration
  def change
    create_table :comment_locations do |t|
      t.references :comment, index: true, foreign_key: true
      t.references :project_file, index: true, foreign_key: true
      t.integer :start_line
      t.integer :start_column
      t.integer :end_line
      t.integer :end_column

      t.timestamps null: false
    end
  end
end
