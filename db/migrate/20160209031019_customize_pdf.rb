class CustomizePdf < ActiveRecord::Migration
  def change
    add_column :charities, :pdf_body, :text, default: nil
    add_column :charities, :pdf_charity_identifier, :string, default: nil
    add_column :charities, :pdf_signature, :string, default: nil
  end
end
