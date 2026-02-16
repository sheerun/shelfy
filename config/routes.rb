Rails.application.routes.draw do
  get "/", to: redirect("/docs")

  namespace :health do
    get "live"
    get "ready"
  end

  resources :readers, only: [:index, :show, :create, :update, :destroy]
  resources :books, only: [:index, :show, :create, :update, :destroy] do
    member do
      post :borrow
      post :return
    end
  end
end
