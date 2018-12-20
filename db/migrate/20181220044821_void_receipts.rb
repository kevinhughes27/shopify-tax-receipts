class VoidReceipts < ActiveRecord::Migration[5.2]
  def change
    add_column :donations, :void, :boolean, default: false, null: false
  end
end
