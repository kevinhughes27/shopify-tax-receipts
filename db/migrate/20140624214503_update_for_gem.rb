class UpdateForGem < ActiveRecord::Migration
  def self.up
    remove_index :charities, :shop_id
    remove_column :charities, :shop_id
    add_column :charities, :shop, :string
    add_index :charities, :shop

    remove_index :products, :shop_id
    remove_column :products, :shop_id
    add_column :products, :shop, :string
    add_index :products, :shop
  end

  def self.down
    add_column :charities, :shop_id
    add_index :charities, :shop_id
    remove_index :charities, :shop
    remove_column :charities, :shop, :string

    add_column :products, :shop_id
    add_index :products, :shop_id
    remove_index :products, :shop
    remove_column :products, :shop, :string
  end
end
