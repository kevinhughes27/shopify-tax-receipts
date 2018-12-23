class VoidTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :charities, :void_email_template, :string
    add_column :charities, :void_email_subject, :string
  end
end
