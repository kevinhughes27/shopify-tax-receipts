class AddShopIndexOnProducts < ActiveRecord::Migration
  def self.up
    add_index :products, :shop_id
  end

  def self.down
    remove_index :products, :shop_id
  end
end
