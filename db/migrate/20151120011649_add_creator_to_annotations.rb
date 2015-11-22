class AddCreatorToAnnotations < ActiveRecord::Migration
  def change
    add_column :comments, :created_by, :integer, foreign_key: true
    add_column :alternative_codes, :created_by, :integer, foreign_key: true
  end
end
