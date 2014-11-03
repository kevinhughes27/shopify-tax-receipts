require 'sinatra/shopify-sinatra-app'
require './lib/models/charity'

class SinatraApp < Sinatra::Base

  post '/charity' do
    shopify_session do
      params.merge!(shop: current_shop_name)

      charity = Charity.new(params)

      if charity.save
        flash[:notice] = "Charity Information Saved"
      else
        flash[:error] = "Error Saving Charity Information"
      end

      redirect '/'
    end
  end

  put '/charity' do
    shopify_session do
      charity = Charity.find_by(shop: current_shop_name)

      if charity.update_attributes(charity_params(params))
        flash[:notice] = "Charity Information Saved"
      else
        flash[:error] = "Error Saving Charity Information"
      end

      redirect '/'
    end
  end

  get '/charity/email_template' do
    shopify_session do
      charity = Charity.find_by(shop: current_shop_name)
      erb :edit_email_modal, locals: {charity: charity}
    end
  end

  put '/charity/email_template' do
    shopify_session do
      charity = Charity.find_by(shop: current_shop_name)
      charity.update_attributes(email_template: params["email_template"])
    end
  end

  def charity_params(params)
    params.slice("name", "charity_id")
  end
end
