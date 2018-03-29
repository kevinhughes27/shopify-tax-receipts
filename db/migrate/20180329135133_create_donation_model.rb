class CreateDonationModel < ActiveRecord::Migration[5.1]
  def change
    create_table :donations do |t|
      t.string :shop
      t.integer :order_id, null: false, limit: 8
      t.decimal :donation_amount, precision: 8, scale: 2, null: false
      t.datetime :created_at, null: false
      t.index :shop
    end
  end
end
