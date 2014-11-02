class CharityAddCustomEmailTemplate < ActiveRecord::Migration
  def self.up
    add_column :charities, :email_template, :string
  end

  def self.down
    remove_column :charities, :email_template
  end
end
