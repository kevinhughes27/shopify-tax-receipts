class DonationThreshold < ActiveRecord::Migration[5.2]
  def change
    add_column :charities, :receipt_threshold, :decimal, precision: 8, scale: 2
  end
end
