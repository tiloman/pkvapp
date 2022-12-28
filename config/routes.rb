Rails.application.routes.draw do
  default_url_options host: 'abile.timolohmann.de'

  resources :operations
  resources :people
  devise_for :users

  devise_scope :user do
    authenticated :user do
      root 'operations#dashboard'# as: :authenticated_root
    end

    unauthenticated do
      root 'static_pages#index', as: :unauthenticated_root
    end
  end

  get 'static_pages/index'
  get 'static_pages/contact'

  get '/calendar', to: 'operations#calendar'
  get '/dashboard', to: 'operations#dashboard'
  resource :webcal, only: :show

  match "/delayed_job" => DelayedJobWeb, :anchor => false, :via => [:get, :post]

end
