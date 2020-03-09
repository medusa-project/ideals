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
    match "/edit-access", to: "collections#edit_access", via: :get
    match "/edit-membership", to: "collections#edit_membership", via: :get
    match "/edit-properties", to: "collections#edit_properties", via: :get
  end
  match "/dashboard", to: "users#dashboard", via: :get
  match "/deposit", to: "items#deposit", via: :get
  resources :handles
  resources :identities do
    collection do
      get 'login'
      get 'register'
    end
  end
  resources :invitees
  resources :items, except: :new do
    match "/cancel-submission", to: "items#cancel_submission", via: :delete
    match "/edit-metadata", to: "items#edit_metadata", via: :get
    match "/edit-properties", to: "items#edit_properties", via: :get
  end
  resources :metadata_profiles, path: "metadata-profiles" do
    match "/clone", to: "metadata_profiles#clone", via: :post
    resources :metadata_profile_elements, path: "elements", except: [:new, :index, :show]
  end
  resources :password_resets, only: [:new, :create, :edit, :update]
  resources :registered_elements, param: :name, path: "elements"
  resources :submission_profiles, path: "submission-profiles" do
    match "/clone", to: "submission_profiles#clone", via: :post
    resources :submission_profile_elements, path: "elements", except: [:new, :index, :show]
  end
  resources :units, except: :new
  resources :user_groups, path: "user-groups", except: :new
  resources :users, except: [:create, :delete]

  # catch unknown routes, but ignore datatables and progress-job routes, which
  # are generated by engines.
  match "/*a" => "errors#error404",
        constraints: lambda{|req| req.path !~/progress-job/ && req.path !~ /datatables/ },
        via: [ :get, :post, :patch, :delete ]

end
