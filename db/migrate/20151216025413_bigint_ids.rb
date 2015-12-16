class BigintIds < ActiveRecord::Migration
  def change
    change_column :products, :product_id, :integer, limit: 8
  end
end
