Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"
  get "confirmation/:token", to: "confirmations#show", as: :confirmation
  resource :settings, only: %i[ show update ]
  resources :friends, only: [ :index, :show, :create, :update, :destroy ] do
    resources :entries, only: %i[ create edit update destroy ]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "friends#index"
end
