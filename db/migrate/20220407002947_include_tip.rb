class IncludeTip < ActiveRecord::Migration[5.2]
  def change
    add_column :charities, :include_tip, :boolean, default: false, null: false
  end
end
