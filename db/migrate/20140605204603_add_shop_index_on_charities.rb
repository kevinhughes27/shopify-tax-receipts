class AddShopIndexOnCharities < ActiveRecord::Migration
  def self.up
    add_index :charities, :shop_id
  end

  def self.down
    remove_index :charities, :shop_id
  end
end
