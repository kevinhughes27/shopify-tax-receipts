class CreateProducts < ActiveRecord::Migration
  def self.up
    create_table :products do |t|
      t.integer :shop_id
      t.integer :product_id
    end
  end

  def self.down
    drop_table :products
  end
end
