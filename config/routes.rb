Spree::Core::Engine.routes.draw do

  get :gtpay_confirm, controller: "checkout", action: "confirm"
  resources :gtpay_transactions, only: :index do
    collection do
      post :callback
    end
  end

  namespace :admin do
    resources :gtpay_transactions, only: :index do
      get :query_interface, on: :member
    end
  end
end
