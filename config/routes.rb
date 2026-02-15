Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  namespace :v1 do
    # Redirect /v1 to API documentation
    get "/", to: redirect("/v1/docs")

    namespace :health do
      get "live"
      get "ready"
    end
  end
end
