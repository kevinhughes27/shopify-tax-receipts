class AddFilenameColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :charities, :pdf_filename, :string, default: 'donation_receipt'
  end
end
