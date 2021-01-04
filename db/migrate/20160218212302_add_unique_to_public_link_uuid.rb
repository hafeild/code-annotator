class AddUniqueToPublicLinkUuid < ActiveRecord::Migration[4.2]
  def change
    remove_index :public_links, :link_uuid
    add_index :public_links, :link_uuid, unique: true
  end
end
