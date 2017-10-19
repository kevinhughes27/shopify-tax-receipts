class SupportDecimalDonations < ActiveRecord::Migration
  def change
    change_column :products, :percentage, :decimal
  end
end
