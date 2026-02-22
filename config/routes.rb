Rails.application.routes.draw do
  use_doorkeeper
  root "root_page#index"

  resources :meetings, only: [ :index, :show ] do
    resources :groups, only: [ :show ], controller: "meetings/groups"
    resource :stale_report, only: [ :create ]
  end
  resources :groups, only: :index
  resources :sessions, only: :index
  resources :documents, only: [ :index, :show ] do
    resource :document_material, only: [ :create, :destroy ]
    resource :stale_report, only: [ :create ]
  end
  resources :session_presentations, only: :index

  # Stale report for meetings/groups show page
  post "/meetings/:meeting_id/groups/:group_id/stale_report",
       to: "stale_reports#create", as: :meeting_group_stale_report

  # GitHub OAuth
  get  "/auth/:provider/callback", to: "auth/sessions#create"
  get  "/auth/failure",            to: "auth/sessions#failure"
  get  "/login",                   to: "auth/sessions#new", as: :login
  delete "/logout",                to: "auth/sessions#destroy", as: :logout

  # OAuth 2.0 Well-Known Metadata (RFC 9728 / RFC 8414)
  # RFC 9728 §3: path-suffix form for resource-specific metadata
  get "/.well-known/oauth-protected-resource/*resource_path", to: "well_known/oauth_metadata#protected_resource"
  get "/.well-known/oauth-protected-resource",                to: "well_known/oauth_metadata#protected_resource"
  get "/.well-known/oauth-authorization-server",              to: "well_known/oauth_metadata#authorization_server"

  # OAuth 2.0 Dynamic Client Registration (RFC 7591)
  post "/oauth/register", to: "oauth/registrations#create"

  mount McpApp.new => "/mcp"

  # Admin
  namespace :admin do
    root to: "dashboard#index"
    resources :stale_reports, only: [ :index ] do
      member do
        patch :acknowledge
        patch :resolve
      end
    end
  end

  # Job monitoring dashboard (admin only)
  mount MissionControl::Jobs::Engine, at: "/admin/jobs"

  # CDN URL for Active Storage files
  direct :public_cdn do |representation, options|
    if Rails.configuration.active_storage.service == :amazon
      "https://#{ENV["CDN_HOST"]}/#{representation.key}"
    else
      url_for(representation)
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
