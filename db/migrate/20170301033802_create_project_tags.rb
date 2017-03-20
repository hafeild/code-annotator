class CreateProjectTags < ActiveRecord::Migration
  def change
    create_table :project_tags do |t|
      t.references :tag, foriegn_key: true 
      t.references :project, foreign_key: true

      t.timestamps null: false
    end
    add_index :project_tags, [:tag_id, :project_id]
  end
end
