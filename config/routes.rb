require "sidekiq/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"

  # Razorpay ("razorback") processor engine — provides POST /webhooks/razorpay.
  mount Pay::RazorbackProcessor::Engine => "/"

  # Browser-facing checkout + onboarding. These dispatch to host controllers
  # (BillingController, WorkspacesController). They live here — not in the
  # razorback engine — so their path helpers register on the application's
  # route set, which is what OnboardingFlow (included in those host
  # controllers) resolves via `send(...)`.
  get  "billing/checkout",     to: "billing#checkout",     as: :billing_checkout
  post "billing/orders",       to: "billing#create_order", as: :billing_orders
  post "billing/charges",      to: "billing#create",       as: :billing_charges
  get  "billing/provisioning", to: "billing#provisioning", as: :billing_provisioning

  resource :billing_workspace, only: [ :edit, :update ],
           path: "billing/workspace", controller: "workspaces"

  # "active" workspaces belong on the frontend dashboard (a separate Next app),
  # so OnboardingFlow's dashboard_path bounces there rather than to a Rails view.
  get "dashboard",
      to: redirect(ENV["FRONTEND_URL"].presence || "http://localhost:3001"),
      as: :dashboard
  resources :tasks do
   post :complete, on: :member
  end
  resources :accounts do
    collection do
      get :export, action: :index, defaults: { format: :xlsx }
      post :import, action: :import, defaults: { format: :xlsx }
    end
  end
  resources :leads do
    post :convert, on: :member
  end
  resources :opportunities
  resources :groups
  resources :users, only: [ :index ]
  resources :activities, only: [ :index ]
  namespace :campaign do
    resources :posts, only: [ :index, :show, :create, :update, :destroy ]
    resources :publications, only: [ :create ]
    resources :social_accounts, only: [ :index, :create ] do
      get :connect_token, on: :collection
      post :refresh, on: :member
    end
  end

  # OAuth connect for social accounts. OmniAuth middleware handles the request
  # phase (POST /auth/:provider); these handle the callback + failure.
  get "/auth/:provider/callback", to: "campaign/omniauth_callbacks#create"
  get "/auth/failure",           to: "campaign/omniauth_callbacks#failure"
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    confirmations: "users/confirmations"
  }
 devise_scope :user do
  get "users/sessions/me", to: "users/sessions#me"
 end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
