class AddPercentage < ActiveRecord::Migration
  def change
    add_column :products, :percentage, :integer, default: 100
  end
end
