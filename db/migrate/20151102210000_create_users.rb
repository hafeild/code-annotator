class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :password_digest
      t.string :activation_digest
      t.boolean :activated
      t.datetime :activated_at
      t.string :remember_digest

      t.timestamps null: false
    end

    add_index :users, :email, unique: true
  end
end
