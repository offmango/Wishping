Wishping::Application.routes.draw do

  devise_for :users, :controllers => {:omniauth_callbacks => "users/omniauth_callbacks"} 

  get "home/index"

  match 'users/:id/add_amazon_item' => 'users#add_amazon_item'
  match 'users/:id/update_prices' => 'users#update_prices', :as => :update_prices

  resources :items

  resources :users do
    match 'items/add_amazon_item' => 'items#add_amazon_item'
    resources :items
  end

  root :to => "home#index"

end
