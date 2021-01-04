class AddCreatorToAnnotations < ActiveRecord::Migration[4.2]
  def change
    add_column :comments, :created_by, :integer, foreign_key: true
    add_column :alternative_codes, :created_by, :integer, foreign_key: true
  end
end
