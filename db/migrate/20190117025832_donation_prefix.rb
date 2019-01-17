class DonationPrefix < ActiveRecord::Migration[5.2]
  def change
    add_column :charities, :donation_id_prefix, :string
  end
end
