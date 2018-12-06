Rails.application.routes.draw do
  root to: 'v1/cert_bundles#index'
  namespace :v1 do
    resources :cert_bundles
  end
end
