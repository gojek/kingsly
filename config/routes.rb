Rails.application.routes.draw do
  namespace :v1 do
    resources :cert_bundles
  end
end
