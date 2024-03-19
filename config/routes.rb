Rails.application.routes.draw do
  root "welcome#index"
  get "/", to: "welcome#index"

  # Authentication routes
  match "/auth/:provider/callback", to: "sessions#create", via: [:get, :post]
  match "/auth/failure", to: "sessions#auth_failed", as: :auth_failed, via: [:get, :post]
  match "/login", to: "sessions#new", as: :login, via: :get
  match "/logout", to: "sessions#destroy", as: :logout, via: :all

  # About
  match "/about", to: "welcome#about", via: :get, as: "about"

  # Collections
  resources :collections, except: :edit do
    # These all render content for the main tab panes in show-unit view via XHR.
    match "/about", to: "collections#show_about", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/access", to: "collections#show_access", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/all-files", to: "collections#all_files", via: :get
    match "/bury", to: "collections#bury", via: :post
    match "/exhume", to: "collections#exhume", via: :post
    match "/items", to: "collections#show_items", via: :get
    match "/review-submissions", to: "collections#show_review_submissions", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/statistics", to: "collections#show_statistics", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/submissions-in-progress", to: "collections#show_submissions_in_progress", via: :get,
          constraints: lambda { |request| request.xhr? }

    match "/children", to: "collections#children", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-administering-groups", to: "collections#edit_administering_groups", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-administering-users", to: "collections#edit_administering_users", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-collection-membership",
          to: "collections#edit_collection_membership", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-properties", to: "collections#edit_properties", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-submitting-groups", to: "collections#edit_submitting_groups", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-submitting-users", to: "collections#edit_submitting_users", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-unit-membership", to: "collections#edit_unit_membership", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/item-results", to: "collections#item_results", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/item-download-counts", to: "collections#item_download_counts", via: :get
    match "/statistics-by-range", to: "collections#statistics_by_range", via: :get
    match "/submit", to: "submissions#new", via: :get
  end

  # Contact form
  match "/contact", to: "welcome#contact", via: :post,
        constraints: lambda { |request| request.xhr? }

  # Credentials
  resources :credentials, only: [:update] do
    match "/edit-password", to: "credentials#edit_password", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/register", to: "credentials#register", via: :get
    match "/reset-password", to: "credentials#new_password", via: :get
    match "/reset-password", to: "credentials#reset_password", via: [:patch, :post]
    match "/update-password", to: "credentials#update_password", via: [:patch, :post],
          constraints: lambda { |request| request.xhr? }
  end

  # Theme route
  match "/custom-styles", to: "stylesheets#show", via: :get

  # Downloads
  resources :downloads, only: :show, param: :key do
    match "/file", to: "downloads#file", via: :get, as: "file"
  end

  # Element Namespaces
  resources :element_namespaces, path: "element-namespaces", except: :show

  # Events
  match "/all-events", to: "events#index_all", via: :get, as: "all_events"
  resources :events, only: [:index, :show]

  # File Formats
  resources :file_formats, path: "file-formats", only: :index

  # Handle
  match "/handle/:prefix/:suffix", to: "handles#redirect", via: :get, as: "redirect_handle"

  # Health Check
  match "/health", to: "health#index", via: :get, as: "health"

  # Imports
  resources :imports do
    match "/complete-upload", to: "imports#complete_upload", via: :post
  end

  # Index Pages
  resources :index_pages, path: "index-pages"

  # Institutions
  resources :institutions, except: [:edit, :update], param: :key do
    # These all render content for the main tab panes in show-unit view via XHR.
    match "/access", to: "institutions#show_access", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/authentication", to: "institutions#show_authentication", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/buried-items", to: "institutions#show_buried_items", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/depositing", to: "institutions#show_depositing", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-administering-groups", to: "institutions#edit_administering_groups", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-administering-users", to: "institutions#edit_administering_users", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/element-mappings/edit", to: "institutions#edit_element_mappings", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-deposit-agreement", to: "institutions#edit_deposit_agreement", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-deposit-help", to: "institutions#edit_deposit_help", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-deposit-questions", to: "institutions#edit_deposit_questions", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-local-authentication", to: "institutions#edit_local_authentication", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-preservation", to: "institutions#edit_preservation", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-properties", to: "institutions#edit_properties", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-saml-authentication", to: "institutions#edit_saml_authentication", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-settings", to: "institutions#edit_settings", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-theme", to: "institutions#edit_theme", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/element-mappings", to: "institutions#show_element_mappings", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/element-namespaces", to: "institutions#show_element_namespaces", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/elements", to: "institutions#show_element_registry", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/imports", to: "institutions#show_imports", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/index-pages", to: "institutions#show_index_pages", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/invitees", to: "institutions#show_invitees", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/metadata-profiles", to: "institutions#show_metadata_profiles", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/prebuilt-searches", to: "institutions#show_prebuilt_searches", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/preservation", to: "institutions#show_preservation", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/private-items", to: "institutions#show_private_items", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/properties", to: "institutions#show_properties", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/review-submissions", to: "institutions#show_review_submissions", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/settings", to: "institutions#show_settings", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/statistics", to: "institutions#show_statistics", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/submission-profiles", to: "institutions#show_submission_profiles", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/submissions-in-progress", to: "institutions#show_submissions_in_progress", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/supply-saml-configuration", to: "institutions#supply_saml_configuration", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/theme", to: "institutions#show_theme", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/units", to: "institutions#show_units", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/usage", to: "institutions#show_usage", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/users", to: "institutions#show_users", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/user-groups", to: "institutions#show_user_groups", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/vocabularies", to: "institutions#show_vocabularies", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/withdrawn-items", to: "institutions#show_withdrawn_items", via: :get,
          constraints: lambda { |request| request.xhr? }

    match "/banner-image", to: "institutions#remove_banner_image", via: :delete
    match "/deposit-agreement-questions", to: "institutions#update_deposit_agreement_questions", via: [:patch, :post]
    match "/favicon", to: "institutions#remove_favicon", via: :delete
    match "/footer-image", to: "institutions#remove_footer_image", via: :delete
    match "/generate-saml-cert", to: "institutions#generate_saml_cert", via: :patch
    match "/generate-saml-key", to: "institutions#generate_saml_key", via: :patch
    match "/header-image", to: "institutions#remove_header_image", via: :delete
    match "/item-download-counts", to: "institutions#item_download_counts", via: :get
    match "/preservation", to: "institutions#update_preservation", via: [:patch, :post]
    match "/properties", to: "institutions#update_properties", via: [:patch, :post]
    match "/refresh-saml-config-metadata", to: "institutions#refresh_saml_config_metadata", via: :patch
    match "/settings", to: "institutions#update_settings", via: [:patch, :post]
    match "/statistics-by-range", to: "institutions#statistics_by_range", via: :get
  end

  # Invitees
  match "/all-invitees", to: "invitees#index_all", via: :get, as: "all_invitees"
  match "/register", to: "invitees#register", via: :get
  resources :invitees, except: [:update] do
    collection do
      match "/create-unsolicited", to: "invitees#create_unsolicited", via: :post,
            as: "create_unsolicited"
    end
    match "/approve", to: "invitees#approve", via: [:patch, :post]
    match "/reject", to: "invitees#reject", via: [:patch, :post]
    match "/resend-email", to: "invitees#resend_email", via: [:patch, :post]
  end

  # Items
  resources :items, except: [:index, :new] do
    collection do
      match "/export", to: "items#export", via: [:get, :post]
      match "/review", to: "items#review", via: :get
      match "/process_review", to: "items#process_review", via: :post
    end
    match "/approve", to: "items#approve", via: :patch
    resources :bitstreams do
      match "/data", to: "bitstreams#data", via: :get
      match "/ingest", to: "bitstreams#ingest", via: :post
      match "/object", to: "bitstreams#object", via: :get
      match "/viewer", to: "bitstreams#viewer", via: :get,
            constraints: lambda { |request| request.xhr? }
    end
    match "/bury", to: "items#bury", via: :post
    match "/download-counts", to: "items#download_counts", via: :get
    match "/exhume", to: "items#exhume", via: :post
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
    # This supports links from file to file in HTML-format bitstreams within iframes.
    match "/files/:filename", to: "bitstreams#data", via: :get
    match "/reject", to: "items#reject", via: :patch
    match "/statistics", to: "items#statistics", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/upload-bitstreams", to: "items#upload_bitstreams", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/withdraw", to: "items#withdraw", via: :patch
  end

  # Messages
  resources :messages, only: [:index, :show] do
    match "/resend", to: "messages#resend", via: :post
  end

  # Metadata Profiles
  resources :metadata_profiles, path: "metadata-profiles" do
    match "/clone", to: "metadata_profiles#clone", via: :post
    resources :metadata_profile_elements, path: "elements", except: [:index, :show]
  end

  # OAI-PMH Endpoint
  match "/dspace-oai/request", to: redirect("/oai-pmh", status: 301), via: :all
  match "/oai-pmh", to: "oai_pmh#handle", via: %w(get post), as: "oai_pmh"

  # Prebuilt Searches
  resources :prebuilt_searches, path: "prebuilt-searches"

  # Recent Items
  match "/recent-items", to: "items#recent", via: :get, as: "recent_items"

  # Reset Password
  match "/reset-password", to: "password_resets#get", via: :get
  match "/reset-password", to: "password_resets#post", via: :post

  # Registered Elements
  resources :registered_elements, except: :show, path: "elements"

  # Robots
  match "/robots", to: "robots#show", via: :get

  # Search
  match "/search", to: "search#index", via: :get

  # Settings
  match "/settings", to: "settings#index", via: :get
  match "/settings", to: "settings#update", via: :patch

  # Submission Profiles
  resources :submission_profiles, path: "submission-profiles" do
    match "/clone", to: "submission_profiles#clone", via: :post
    resources :submission_profile_elements, path: "elements", except: [:index, :show]
  end

  # Submissions
  match "/submit", to: "submissions#new", via: :get
  resources :submissions, except: [:index, :show] do
    match "/complete", to: "submissions#complete", via: :post
    match "/status", to: "submissions#status", via: :get
  end

  # Tasks
  match "/all-tasks", to: "tasks#index_all", via: :get, as: "all_tasks"
  resources :tasks, only: [:index, :show]

  # Template Elements
  match "/template-elements", to: "registered_elements#index_template", via: :get

  # Units
  resources :units, except: :edit do
    match "/about", to: "units#show_about", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/access", to: "units#show_access", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/bury", to: "units#bury", via: :post
    match "/collections", to: "units#show_collections", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/exhume", to: "units#exhume", via: :post
    match "/items", to: "units#show_items", via: :get
    match "/statistics", to: "units#show_statistics", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/children", to: "units#children", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/collections-tree-fragment", to: "units#collections_tree_fragment", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-administering-groups", to: "units#edit_administering_groups", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-administering-users", to: "units#edit_administering_users", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-membership", to: "units#edit_membership", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/edit-properties", to: "units#edit_properties", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/item-results", to: "units#item_results", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/item-download-counts", to: "units#item_download_counts", via: :get
    match "/review-submissions", to: "units#show_review_submissions", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/statistics-by-range", to: "units#statistics_by_range", via: :get
    match "/submissions-in-progress", to: "units#show_submissions_in_progress", via: :get,
          constraints: lambda { |request| request.xhr? }
  end

  # Usage
  match "/usage", to: "usage#index", via: :get
  match "/usage/files", to: "usage#files", via: :get,
        constraints: lambda { |request| request.xhr? }
  match "/usage/items", to: "usage#items", via: :get,
        constraints: lambda { |request| request.xhr? }

  # User Groups
  match "/global-user-groups", to: "user_groups#index_global", via: :get,
        as: "global_user_groups"
  resources :user_groups, path: "user-groups" do
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
    match "/edit-users", to: "user_groups#edit_users", via: :get,
          constraints: lambda { |request| request.xhr? }
  end

  # Users
  match "/all-users", to: "users#index_all", via: :get, as: "all_users"
  resources :users, only: [:index, :show] do
    resources :credentials, only: [:create, :new]
    match "/credentials", to: "users#show_credentials", via: :get,
          constraints: lambda { |request| request.xhr? }
    match "/disable", to: "users#disable", via: :patch
    match "/enable", to: "users#enable", via: :patch
    match "/logins", to: "users#show_logins", via: :get,
          constraints: lambda { |request| request.xhr? }
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
    match "/update-submittable-collections", to: "users#update_submittable_collections", via: [:patch, :post],
          constraints: lambda { |request| request.xhr? }
  end

  # Vocabularies
  resources :vocabularies do
    resources :vocabulary_terms, path: "terms", except: [:index, :show]
    match "/terms/import", to: "vocabulary_terms#import", via: [:get, :post]
  end

  match "/*a" => "errors#error404", via: :all

end
