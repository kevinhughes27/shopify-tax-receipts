class DenormOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :donations, :order, :string
  end
end
