class CreateCharity < ActiveRecord::Migration
  def self.up
    create_table :charities do |t|
      t.integer :shop_id
      t.string :name
    end
  end

  def self.down
    drop_table :charities
  end
end
