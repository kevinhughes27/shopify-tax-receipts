class VoidReceipts < ActiveRecord::Migration[5.2]
  def change
    add_column :donations, :status, :string
  end
end
