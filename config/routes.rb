Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "home#index"

  resources :groups, only: [ :new, :create ]

  scope "/g/:token" do
    get "/", to: "groups#show", as: :group_show
    get "/settlements", to: "settlements#show", as: :group_settlements
    resources :payments, only: [ :new, :create, :edit, :update, :destroy ], as: :group_payments
    resources :members, only: [ :create, :destroy ], as: :group_members
  end
end
