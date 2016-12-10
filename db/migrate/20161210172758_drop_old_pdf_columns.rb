class DropOldPdfColumns < ActiveRecord::Migration
  def change
    remove_column :charities, :pdf_body
    remove_column :charities, :pdf_charity_identifier
    remove_column :charities, :pdf_signature
  end
end
