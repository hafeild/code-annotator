class CreateProjectFiles < ActiveRecord::Migration[4.2]
  def change
    create_table :project_files do |t|
      t.string :name
      t.integer :added_by, foreign_key: true
      t.belongs_to :project, index: true, foreign_key: true
      t.integer :size

      t.timestamps null: false
    end
  end
end
