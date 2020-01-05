class AddDiscountsSetting < ActiveRecord::Migration[5.2]
  def change
    add_column :charities, :subtract_discounts, :boolean, default: false, null: false
  end
end
