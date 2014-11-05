class AddEmailSubject < ActiveRecord::Migration
  def self.up
    add_column :charities, :email_subject, :string
  end

  def self.down
    remove_column :charities, :email_subject
  end
end
