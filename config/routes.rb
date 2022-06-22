Rails.application.routes.draw do
  root 'welcome#index'
  get '/', to: 'welcome#index'

  # authentication routes
  match "/auth/:provider/callback", to: "sessions#create", via: [:get, :post]
  match "/auth/failure", to: "sessions#unauthorized", as: :unauthorized, via: [:get, :post]
  match "/login", to: "sessions#new", as: :login, via: :get
  match "/logout", to: "sessions#destroy", as: :logout, via: :all
  match "/netid-login", to: "sessions#new_netid", as: :netid_login, via: [:get, :post]

  resources :collections, except: [:destroy, :edit, :new] do
    # These all render content for the main tab panes in show-unit view via XHR.
    match "/about", to: "collections#show_about", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/access", to: "collections#show_access", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/delete", to: "collections#delete", via: :post # different from destroy--see method doc
    match "/items", to: "collections#show_items", via: :get
    match "/review-submissions", to: "collections#show_review_submissions", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/statistics", to: "collections#show_statistics", via: :get,
          constraints: lambda { |request| request.xhr? }

    match "/children", to: "collections#children", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-managers", to: "collections#edit_managers", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-collection-membership",
          to: "collections#edit_collection_membership", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-properties", to: "collections#edit_properties", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-submitters", to: "collections#edit_submitters", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-unit-membership", to: "collections#edit_unit_membership", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/item-results", to: "collections#item_results", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/item-download-counts", to: "collections#item_download_counts", via: :get
    match "/statistics-by-range", to: "collections#statistics_by_range", via: :get
    match "/submit", to: "submissions#new", via: :get
    match "/undelete", to: "collections#undelete", via: :post
  end
  # This is an old DSpace route.
  match "/dspace-oai/request", to: redirect('/oai-pmh', status: 301), via: :all
  resources :file_formats, path: "file-formats", only: :index
  match "/handle/:prefix/:suffix", to: "handles#redirect", via: :get, as: "redirect_handle"
  resources :imports do
    match "/delete-all-files", to: "imports#delete_all_files", via: :post
    match "/upload-file", to: "imports#upload_file", via: :post
  end
  resources :institutions, param: :key do
    # These all render content for the main tab panes in show-unit view via XHR.
    match "/properties", to: "institutions#show_properties", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/statistics", to: "institutions#show_statistics", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/users", to: "institutions#show_users", via: :get,
          constraints: lambda { |request| request.xhr? }

    match "/item-download-counts", to: "institutions#item_download_counts", via: :get
    match "/statistics-by-range", to: "institutions#statistics_by_range", via: :get
  end
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
  match "/items/export", to: "items#export", via: [:get, :post]
  match "/items/review", to: "items#review", via: :get
  match "/items/process_review", to: "items#process_review", via: :post
  resources :items, except: [:destroy, :new] do
    match "/approve", to: "items#approve", via: :patch
    resources :bitstreams do
      match "/ingest", to: "bitstreams#ingest", via: :post
      match "/object", to: "bitstreams#object", via: :get
      match "/stream", to: "bitstreams#stream", via: :get
      match "/viewer", to: "bitstreams#viewer", via: :get,
            constraints: lambda { |request| request.xhr? }
    end
    match "/delete", to: "items#delete", via: :post # different from destroy--see method doc
    match "/download-counts", to: "items#download_counts", via: :get
    match "/edit-embargoes", to: "items#edit_embargoes", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-membership", to: "items#edit_membership", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-metadata", to: "items#edit_metadata", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-properties", to: "items#edit_properties", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-withdrawal", to: "items#edit_withdrawal", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/file-navigator", to: "items#file_navigator", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/reject", to: "items#reject", via: :patch
    match "/statistics", to: "items#statistics", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/undelete", to: "items#undelete", via: :post
    match "/upload-bitstreams", to: "items#upload_bitstreams", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/withdraw", to: "items#withdraw", via: :patch
  end
  resources :messages, only: [:index, :show]
  resources :metadata_profiles, path: "metadata-profiles" do
    match "/clone", to: "metadata_profiles#clone", via: :post
    match "/reindex-items", to: "metadata_profiles#reindex_items", via: :post
    resources :metadata_profile_elements, path: "elements", except: [:new, :index, :show]
  end
  match '/oai-pmh', to: 'oai_pmh#handle', via: %w(get post), as: 'oai_pmh'
  match "/reset-password", to: "password_resets#get", via: :get
  match "/reset-password", to: "password_resets#post", via: :post
  resources :registered_elements, param: :name, path: "elements"
  match "/settings", to: "settings#index", via: :get
  match "/settings", to: "settings#update", via: :patch
  resources :submission_profiles, path: "submission-profiles" do
    match "/clone", to: "submission_profiles#clone", via: :post
    resources :submission_profile_elements, path: "elements", except: [:new, :index, :show]
  end
  resources :submissions, except: [:index, :show] do
    match "/complete", to: "submissions#complete", via: :post
    match "/status", to: "submissions#status", via: :get
  end
  match "/submit", to: "submissions#new", via: :get
  resources :tasks, only: [:index, :show]
  resources :units, except: [:destroy, :edit] do
    match "/about", to: "units#show_about", via: :get,
          constraints: lambda { |request| request.xhr? }
    # These all render content for the main tab panes in show-unit view via XHR.
    match "/access", to: "units#show_access", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/delete", to: "units#delete", via: :post # different from destroy--see method doc
    match "/items", to: "units#show_items", via: :get
    match "/statistics", to: "units#show_statistics", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/children", to: "units#children", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/collections-tree-fragment", to: "units#collections_tree_fragment", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-administrators", to: "units#edit_administrators", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-membership", to: "units#edit_membership", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-properties", to: "units#edit_properties", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/item-results", to: "units#item_results", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/item-download-counts", to: "units#item_download_counts", via: :get
    match "/statistics-by-range", to: "units#statistics_by_range", via: :get
    match "/undelete", to: "units#undelete", via: :post
  end
  resources :user_groups, path: "user-groups", except: :new do
    match "/edit-ad-groups", to: "user_groups#edit_ad_groups", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-affiliations", to: "user_groups#edit_affiliations", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-departments", to: "user_groups#edit_departments", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-email-patterns", to: "user_groups#edit_email_patterns", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-hosts", to: "user_groups#edit_hosts", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-local-users", to: "user_groups#edit_local_users", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-netid-users", to: "user_groups#edit_netid_users", via: :get,
          constraints: lambda { |request| request.xhr? }
  end
  resources :users, only: [:index, :show] do
    match "/submitted-item-results", to: "users#submitted_item_results", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/privileges", to: "users#show_privileges", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/properties", to: "users#show_properties", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/submittable-collections", to: "users#show_submittable_collections", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/submitted-items", to: "users#show_submitted_items", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/submissions-in-progress", to: "users#show_submissions_in_progress", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-properties", to: "users#edit_properties", via: :get,
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
