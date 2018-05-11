class AddOrderNumber < ActiveRecord::Migration[5.1]
  def change
    add_column :donations, :order_number, :string
  end
end
