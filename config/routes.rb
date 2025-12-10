require "sidekiq/web"
require "sidekiq-scheduler/web"

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  mount Sidekiq::Web => "/sidekiq"

  namespace :api do
    namespace :v1 do
      resources :users, only: [:create]
      resources :auth, only: [] do
        collection do
          post :login_with_password
          post :logout
        end
      end
    end
  end
end
