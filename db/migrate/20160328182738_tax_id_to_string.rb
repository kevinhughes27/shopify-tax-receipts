class TaxIdToString < ActiveRecord::Migration
  def change
    change_column :charities, :charity_id, :string
  end
end
