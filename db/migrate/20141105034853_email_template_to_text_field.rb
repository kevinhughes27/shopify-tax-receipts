class EmailTemplateToTextField < ActiveRecord::Migration
    def self.up
    change_column :charities, :email_template, :text
  end

  def self.down
    change_column :charities, :email_template, :string
  end
end
