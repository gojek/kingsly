Rails.application.routes.draw do
  resource :ping, only: [:show]
  root to: 'v1/cert_bundles#index'
  namespace :v1 do
    resources :cert_bundles, only: [:create, :index, :show, :delete]
  end
end
