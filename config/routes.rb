Rails.application.routes.draw do
  get "pages/home"
  resources :recipes do
    resources :comments, only: [:create, :destroy]
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
  resources :shopping_list_items, only: [:index, :update, :destroy] do
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
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
