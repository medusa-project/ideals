Rails.application.routes.draw do

  resources :items
  resources :handles
  resources :units, except: :new
  resources :users, except: [:create, :delete]
  resources :collections, except: [:edit, :new] do
    match "/edit-access", to: "collections#edit_access", via: :get
    match "/edit-membership", to: "collections#edit_membership", via: :get
    match "/edit-properties", to: "collections#edit_properties", via: :get
  end
  resources :metadata_profiles, path: "metadata-profiles" do
    match "/clone", to: "metadata_profiles#clone", via: :post
    resources :metadata_profile_elements, path: "elements", except: [:new, :index, :show]
  end
  resources :registered_elements, param: :name, path: "elements"
  resources :submission_profiles, path: "submission-profiles" do
    match "/clone", to: "submission_profiles#clone", via: :post
    resources :submission_profile_elements, path: "elements", except: [:new, :index, :show]
  end
  resources :user_groups, path: "user-groups", except: :new

  root 'welcome#index'
  get '/', to: 'welcome#index'
  get '/dashboard', to: 'welcome#dashboard'
  get '/deposit', to: "welcome#deposit"

  # authentication routes
  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  match '/login', to: 'sessions#new', as: :login, via: [:get, :post]
  match '/logout', to: 'sessions#destroy', as: :logout, via: :all
  match '/auth/failure', to: 'sessions#unauthorized', as: :unauthorized, via: [:get, :post]

  # handle routing
  get '/handle/:prefix/:suffix', to: 'handles#resolve'

  # resources
  resources :identities do
    collection do
      get 'login'
      get 'register'
    end
  end
  resources :invitees
  resources :password_resets, only: [:new, :create, :edit, :update]
  resources :account_activations, only: [:edit]

  # catch unknown routes, but ignore datatables and progress-job routes, which are generated by engines.
  match "/*a" => "errors#error404", :constraints => lambda{|req| req.path !~/progress-job/ && req.path !~ /datatables/ }, via: [ :get, :post, :patch, :delete ]

end
