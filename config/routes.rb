Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"
  get "confirmation/:token", to: "confirmations#show", as: :confirmation
  resource :settings, only: %i[ show update ]
  resource :time_zone, only: :update
  resources :categories, only: %i[ index create update destroy ] do
    get :person_suggestions, on: :collection
  end
  get "people/import", to: "vcard_imports#new", as: :new_vcard_import
  post "people/import", to: "vcard_imports#create", as: :vcard_imports
  get "people/import/preview", to: "vcard_imports#show", as: :vcard_import
  patch "people/import/preview", to: "vcard_imports#update"
  get "people/batch", to: "batch_person_creations#new", as: :new_batch_person_creation
  post "people/batch/preview", to: "batch_person_creations#preview", as: :preview_batch_person_creation
  post "people/batch", to: "batch_person_creations#create", as: :batch_person_creation
  resources :people, only: [ :index, :show, :create, :update, :destroy ] do
    patch :archive, on: :member
    patch :restore, on: :member
    resource :category_assignment, only: :update
    resources :entries, only: %i[ new create edit update destroy ] do
      patch :reorder, on: :collection
    end
    resources :interactions, only: %i[ index new create edit update destroy ]
    resource :keep_in_touch_setting, only: %i[ create update ] do
      patch :enable
      patch :disable
      patch :snooze
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "birthdays", to: "birthdays#index"

  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "people#index"
end
