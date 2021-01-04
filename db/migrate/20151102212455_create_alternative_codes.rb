class CreateAlternativeCodes < ActiveRecord::Migration[4.2]
  def change
    create_table :alternative_codes do |t|
      t.text :content
      t.references :project_file, index: true, foreign_key: true
      t.integer :start_line
      t.integer :start_column
      t.integer :end_line
      t.integer :end_column

      t.timestamps null: false
    end
  end
end
