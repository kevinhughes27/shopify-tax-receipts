require 'sinatra/shopify-sinatra-app'
require_relative '../models/charity'

class SinatraApp < Sinatra::Base
  post '/charity' do
    shopify_session do |shop_name|
      charity = Charity.new(
        name: params['name'],
        charity_id: params['charity_id'],
        shop: shop_name
      )

      if charity.save
        flash[:notice] = "Charity Information Saved"
      else
        flash[:error] = "Error Saving Charity Information"
      end

      redirect '/'
    end
  end

  put '/charity' do
    shopify_session do |shop_name|
      charity = Charity.find_by(shop: shop_name)

      if charity.update_attributes(charity_params(params))
        flash[:notice] = "Saved"
      else
        flash[:error] = "Error Saving"
      end

      redirect '/'
    end
  end

  def charity_params(params)
    params.slice(
      "name",
      "charity_id",
      "email_from",
      "email_bcc",
      "email_subject",
      "email_template",
      "void_email_subject",
      "void_email_template",
      "pdf_template",
      "pdf_filename"
    )
  end
end
