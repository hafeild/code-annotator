class CreateProjects < ActiveRecord::Migration[4.2]
  def change
    create_table :projects do |t|
      t.string :name
      t.integer :created_by, foreign_key: true

      t.timestamps null: false
    end
  end
end
