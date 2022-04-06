class AddTip < ActiveRecord::Migration[5.2]
  def change
      add_column :charities, :add_tip, :boolean, default: false, null: false
  end
end