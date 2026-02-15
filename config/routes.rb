Rails.application.routes.draw do
  get "/", to: redirect("/docs")

  namespace :health do
    get "live"
    get "ready"
  end
end
