Rails.application.routes.draw do
  use_doorkeeper
  root "meetings#index"

  resources :meetings, only: :index
  resources :groups, only: :index
  resources :sessions, only: :index
  resources :documents, only: :index
  resources :session_presentations, only: :index

  # GitHub OAuth
  get  "/auth/:provider/callback", to: "auth/sessions#create"
  get  "/auth/failure",            to: "auth/sessions#failure"
  get  "/login",                   to: "auth/sessions#new", as: :login
  delete "/logout",                to: "auth/sessions#destroy", as: :logout

  mount McpApp.new => "/mcp"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
