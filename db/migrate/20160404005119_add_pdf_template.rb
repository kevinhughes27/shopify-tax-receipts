class AddPdfTemplate < ActiveRecord::Migration
  def change
    add_column :charities, :pdf_template, :text
  end
end
