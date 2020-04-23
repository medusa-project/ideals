Rails.application.routes.draw do
  root 'welcome#index'
  get '/', to: 'welcome#index'

  # authentication routes
  match "/auth/:provider/callback", to: "sessions#create", via: [:get, :post]
  match "/login", to: "sessions#new", as: :login, via: :get
  match "/netid-login", to: "sessions#new_netid", as: :netid_login, via: [:get, :post]
  match "/logout", to: "sessions#destroy", as: :logout, via: :all
  match "/auth/failure", to: "sessions#unauthorized", as: :unauthorized, via: [:get, :post]

  # handle routing
  get '/handle/:prefix/:suffix', to: 'handles#resolve'

  resources :account_activations, only: [:edit]
  resources :collections, except: [:edit, :new] do
    match "/children", to: "collections#children", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/deposit", to: "submissions#agreement", via: :get
    match "/edit-access", to: "collections#edit_access", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-collection-membership",
          to: "collections#edit_collection_membership", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-properties", to: "collections#edit_properties", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-unit-membership", to: "collections#edit_unit_membership", via: :get,
          constraints: lambda { |request| request.xhr? }
  end
  match "/dashboard", to: "dashboard#index", via: :get
  match "/deposit", to: "submissions#agreement", via: :get
  resources :handles
  resources :identities, only: [:create, :destroy, :update] do
    collection do
      get "login"
      get "register"
    end
    match "/reset-password", to: "identities#new_password", via: :get
    match "/reset-password", to: "identities#reset_password", via: [:patch, :post]
  end
  resources :invitees
  resources :items, except: :new do
    resources :bitstreams, only: [:create, :destroy, :show]
    match "/edit-membership", to: "items#edit_membership", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-metadata", to: "items#edit_metadata", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-properties", to: "items#edit_properties", via: :get,
          constraints: lambda { |request| request.xhr? }
  end
  resources :metadata_profiles, path: "metadata-profiles" do
    match "/clone", to: "metadata_profiles#clone", via: :post
    resources :metadata_profile_elements, path: "elements", except: [:new, :index, :show]
  end
  match "/reset-password", to: "password_resets#get", via: :get
  match "/reset-password", to: "password_resets#post", via: :post
  resources :registered_elements, param: :name, path: "elements"
  resources :submission_profiles, path: "submission-profiles" do
    match "/clone", to: "submission_profiles#clone", via: :post
    resources :submission_profile_elements, path: "elements", except: [:new, :index, :show]
  end
  resources :submissions, except: [:index, :show]
  resources :units, except: [:edit, :new] do
    match "/children", to: "units#children", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/collections", to: "units#collections", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-access", to: "units#edit_access", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-membership", to: "units#edit_membership", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-properties", to: "units#edit_properties", via: :get,
          constraints: lambda { |request| request.xhr? }
  end
  resources :user_groups, path: "user-groups", except: :new
  resources :users, except: [:create, :delete]

  # catch unknown routes, but ignore datatables and progress-job routes, which
  # are generated by engines.
  match "/*a" => "errors#error404",
        constraints: lambda{|req| req.path !~/progress-job/ && req.path !~ /datatables/ },
        via: [ :get, :post, :patch, :delete ]

end
