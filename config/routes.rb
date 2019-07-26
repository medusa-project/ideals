Rails.application.routes.draw do

  resources :collections do
    resources :managers
  end

  resources :managers do
    resources :collections
  end

  post '/collections/:id/add_manager', to: 'collections#add_manager'
  post '/collections/:id/remove_manager', to: 'collections#remove_manager'
  post '/managers/:id/take_on_collection', to: 'managers#take_on_collection'
  post '/managers/:id/release_collection', to: 'managers#release_collection'

  # You can have the root of your site routed with "root"
  root 'welcome#index'
  get '/', to: 'welcome#index'
  get '/login_choice', to: 'welcome#login_choice'
  get '/dashboard', to: 'welcome#dashboard'
  get '/deposit', to: "welcome#deposit"
  get '/help', to: 'welcome#help'
  get '/items', to: 'welcome#items'
  get '/policies', to: 'welcome#policies'

  # authentication routes
  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  match '/login', to: 'sessions#new', as: :login, via: [:get, :post]
  match '/logout', to: 'sessions#destroy', as: :logout, via: [:get, :post]

  match '/auth/failure', to: 'sessions#unauthorized', as: :unauthorized, via: [:get, :post]

  # resources
  resources :identities do
    collection do
      get 'login'
      get 'register'
    end
  end
  resources :invitees do
    collection do
      get 'petition'
      get 'pending'
    end
  end

  resources :password_resets, only: [:new, :create, :edit, :update]
  resources :account_activations, only: [:edit]

  # catch unknown routes, but ignore datatables and progress-job routes, which are generated by engines.
  match "/*a" => "errors#error404", :constraints => lambda{|req| req.path !~/progress-job/ && req.path !~ /datatables/ }, via: [ :get, :post, :patch, :delete ]

end
