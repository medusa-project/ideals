Rails.application.routes.draw do
  root 'welcome#index'
  get '/', to: 'welcome#index'

  # authentication routes
  match "/auth/:provider/callback", to: "sessions#create", via: [:get, :post]
  match "/auth/failure", to: "sessions#unauthorized", as: :unauthorized, via: [:get, :post]
  match "/login", to: "sessions#new", as: :login, via: :get
  match "/logout", to: "sessions#destroy", as: :logout, via: :all
  match "/netid-login", to: "sessions#new_netid", as: :netid_login, via: [:get, :post]

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
    match "/item-download-counts", to: "collections#item_download_counts", via: :get
    match "/statistics", to: "collections#statistics", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/statistics-by-range", to: "collections#statistics_by_range", via: :get
  end
  match "/deposit", to: "submissions#agreement", via: :get
  resources :institutions, param: :key
  resources :local_identities, only: [:update], path: "identities" do
    match "/activate", to: "local_identities#activate", via: :get
    match "/edit-password", to: "local_identities#edit_password", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/register", to: "local_identities#register", via: :get
    match "/reset-password", to: "local_identities#new_password", via: :get
    match "/reset-password", to: "local_identities#reset_password", via: [:patch, :post]
    match "/update-password", to: "local_identities#update_password", via: [:patch, :post],
          constraints: lambda { |request| request.xhr? }
  end
  resources :invitees, except: [:edit, :update] do
    collection do
      match "/create", to: "invitees#create_unsolicited", via: :post,
            as: "create_unsolicited"
    end
    match "/approve", to: "invitees#approve", via: [:patch, :post]
    match "/reject", to: "invitees#reject", via: [:patch, :post]
    match "/resend-email", to: "invitees#resend_email", via: [:patch, :post]
  end
  match "/items/review", to: "items#review", via: :get
  match "/items/process_review", to: "items#process_review", via: :post
  resources :items, except: :new do
    resources :bitstreams do
      match "/data", to: "bitstreams#data", via: :get
      match "/ingest", to: "bitstreams#ingest", via: :post
    end
    match "/download-counts", to: "items#download_counts", via: :get
    match "/edit-membership", to: "items#edit_membership", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-metadata", to: "items#edit_metadata", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-properties", to: "items#edit_properties", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/statistics", to: "items#statistics", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/upload-bitstreams", to: "items#upload_bitstreams", via: :get,
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
  resources :submissions, except: [:index, :show] do
    match "/complete", to: "submissions#complete", via: :post
  end
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
    match "/item-download-counts", to: "units#item_download_counts", via: :get
    match "/statistics", to: "units#statistics", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/statistics-by-range", to: "units#statistics_by_range", via: :get
  end
  resources :user_groups, path: "user-groups", except: :new
  resources :users, only: [:index, :show] do
    match "/edit-privileges", to: "users#edit_privileges", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-properties", to: "users#edit_properties", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/update-privileges", to: "users#update_privileges", via: [:patch, :post],
          constraints: lambda { |request| request.xhr? }
    match "/update-properties", to: "users#update_properties", via: [:patch, :post],
          constraints: lambda { |request| request.xhr? }
  end

  # catch unknown routes, but ignore datatables and progress-job routes, which
  # are generated by engines.
  match "/*a" => "errors#error404",
        constraints: lambda{|req| req.path !~/progress-job/ && req.path !~ /datatables/ },
        via: :all

end
