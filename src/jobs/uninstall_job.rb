class UninstallJob < Job
  def perform(shop_name)
    Shop.where(name: shop_name).destroy_all
    Charity.where(shop: shop_name).destroy_all
    Product.where(shop: shop_name).destroy_all
  end
end
