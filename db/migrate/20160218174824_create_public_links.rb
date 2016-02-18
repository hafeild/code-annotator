class CreatePublicLinks < ActiveRecord::Migration
  def change
    create_table :public_links do |t|
      t.string :link_uuid, index: true, unique: true
      t.belongs_to :project, index: true, foreign_key: true
      t.string :name
    end
  end
end
