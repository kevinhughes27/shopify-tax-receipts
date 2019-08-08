class AddProductTemplate < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :email_template, :text, default: nil
  end
end
