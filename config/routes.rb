Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  devise_for :admin_users, ActiveAdmin::Devise.config
  
  
   devise_for :users
  resource :profile, controller: 'users', only: [:show, :edit, :update, :destroy]
  # Role selection routes
  resource :role_selection, only: [:new, :create]

  get "pages/home"
  resources :recipes do
    resources :comments, only: [:create, :destroy]
  end

  namespace :api do
    namespace :v1 do
      resources :recipes, only: [:index, :show, :create, :update, :destroy]
      # Add other API resources as needed
      # resources :comments, only: [:create, :destroy]
    end
  end

  
  # Meal Plans routes
  resources :meal_plans do
    resources :meal_plan_items, only: [:create, :destroy] do
      collection do
        post :add_to_shopping_list
      end
    end
    
    resources :comments, only: [:create, :destroy]
  end

  # Shopping List Items
  resources :shopping_list_items, only: [:index, :create, :update, :destroy] do
    collection do
      delete :clear_purchased
    end
  end

  resources :payments, only: [:index, :create, :update, :destroy] do
    collection do
      delete :clear_completed
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root 'pages#home'
  # Summary/Reports routes

  # Summary/Reports routes
  resources :summaries, only: [:index, :show] do
    collection do
      get 'recipes', to: 'summaries#recipes'
      get 'meal_plans', to: 'summaries#meal_plans'
      get 'shopping', to: 'summaries#shopping'
      get 'payments', to: 'summaries#payments'
    end
  end
# get 'summaries', to: 'summaries#index', as: 'summaries'
# get 'summaries/recipes', to: 'summaries#recipes', as: 'summaries_recipes'
# get 'summaries/meal_plans', to: 'summaries#meal_plans', as: 'summaries_meal_plans'
# get 'summaries/shopping', to: 'summaries#shopping', as: 'summaries_shopping'
# get 'summaries/payments', to: 'summaries#payments', as: 'summaries_payments'
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
