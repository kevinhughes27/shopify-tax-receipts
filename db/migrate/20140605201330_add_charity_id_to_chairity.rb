class AddCharityIdToChairity < ActiveRecord::Migration
  def self.up
    add_column :charities, :charity_id, :integer
  end

  def self.down
    remove_column :charities, :charity_id
  end
end
