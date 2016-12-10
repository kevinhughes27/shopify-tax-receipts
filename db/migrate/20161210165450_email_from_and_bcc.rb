class EmailFromAndBcc < ActiveRecord::Migration
  def change
    add_column :charities, :email_from, :string
    add_column :charities, :email_bcc, :string
  end
end
