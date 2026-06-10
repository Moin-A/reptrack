require "sidekiq/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"
  resources :tasks
  resources :accounts do
    collection do
      get :export, action: :index, defaults: { format: :xls }
    end
  end
  resources :leads
  resources :groups
  resources :users, only: [ :index ]
  resources :activities, only: [ :index ]
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
