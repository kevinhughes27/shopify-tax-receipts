class DonationNumConstraints < ActiveRecord::Migration[5.2]
  def change
    change_column :donations, :donation_number, :int, null: false
    add_index :donations, [:shop, :donation_number], unique: true
  end
end
