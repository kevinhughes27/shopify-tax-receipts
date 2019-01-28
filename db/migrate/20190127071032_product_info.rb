class ProductInfo < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :shopify_product, :text
  end
end
