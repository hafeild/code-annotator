class CreateTags < ActiveRecord::Migration[4.2]
  def change
    create_table :tags do |t|
      t.string :text
      t.references :user, foreign_key: true
      t.timestamps null: false
    end
    add_index :tags, [:text, :user_id]

  end
end
