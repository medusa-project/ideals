class AddLengthLimitsToTextColumns < ActiveRecord::Migration[7.1]
  def change
    change_column :ad_groups, :name, :string, limit: 1024

    change_column :affiliations, :name, :string, limit: 1024
    change_column :affiliations, :key, :string, limit: 128

    change_column :ascribed_elements, :string, :string, limit: 1048576
    change_column :ascribed_elements, :uri, :string, limit: 4096

    change_column :bitstreams, :medusa_uuid, :string, limit: 36
    change_column :bitstreams, :description, :string, limit: 32768

    change_column :collections, :title, :string, limit: 1024
    change_column :collections, :description, :string, limit: 32768
    change_column :collections, :short_description, :string, limit: 8192
    change_column :collections, :introduction, :string, limit: 16384
    change_column :collections, :rights, :string, limit: 16384
    change_column :collections, :provenance, :string, limit: 16384

    change_column :credentials, :email, :string, limit: 1024
    change_column :credentials, :lowercase_email, :string, limit: 1024

    change_column :departments, :name, :string, limit: 1024

    change_column :deposit_agreement_question_responses, :text, :string, limit: 1024

    change_column :deposit_agreement_questions, :text, :string, limit: 4096
    change_column :deposit_agreement_questions, :help_text, :string, limit: 4096

    change_column :downloads, :key, :string, limit: 32
    change_column :downloads, :filename, :string, limit: 4096
    change_column :downloads, :url, :string, limit: 4096
    change_column :downloads, :ip_address, :string, limit: 128

    change_column :element_namespaces, :prefix, :string, limit: 128
    change_column :element_namespaces, :uri, :string, limit: 4096

    change_column :email_patterns, :pattern, :string, limit: 128

    change_column :embargoes, :reason, :string, limit: 4096
    change_column :embargoes, :public_reason, :string, limit: 4096

    change_column :hosts, :pattern, :string, limit: 2048

    change_column :imports, :filename, :string, limit: 4096

    change_column :index_pages, :name, :string, limit: 1024

    change_column :institutions, :key, :string, limit: 32
    change_column :institutions, :name, :string, limit: 1024
    change_column :institutions, :fqdn, :string, limit: 256
    change_column :institutions, :feedback_email, :string, limit: 4096
    change_column :institutions, :footer_background_color, :string, limit: 128
    change_column :institutions, :header_background_color, :string, limit: 128
    change_column :institutions, :link_color, :string, limit: 128
    change_column :institutions, :link_hover_color, :string, limit: 128
    change_column :institutions, :primary_color, :string, limit: 128
    change_column :institutions, :primary_hover_color, :string, limit: 128
    change_column :institutions, :header_image_filename, :string, limit: 1024
    change_column :institutions, :footer_image_filename, :string, limit: 1024
    change_column :institutions, :main_website_url, :string, limit: 1024
    change_column :institutions, :welcome_html, :string, limit: 32768
    change_column :institutions, :active_link_color, :string, limit: 128
    change_column :institutions, :banner_image_filename, :string, limit: 1024
    change_column :institutions, :copyright_notice, :string, limit: 256
    change_column :institutions, :service_name, :string, limit: 128
    change_column :institutions, :about_url, :string, limit: 4096
    change_column :institutions, :about_html, :string, limit: 65536
    change_column :institutions, :outgoing_message_queue, :string, limit: 128
    change_column :institutions, :incoming_message_queue, :string, limit: 128
    change_column :institutions, :deposit_agreement, :string, limit: 32768
    change_column :institutions, :saml_idp_sso_post_service_url, :string, limit: 4096
    change_column :institutions, :saml_idp_signing_cert, :string, limit: 4096
    change_column :institutions, :saml_email_attribute, :string, limit: 128
    change_column :institutions, :saml_first_name_attribute, :string, limit: 128
    change_column :institutions, :saml_last_name_attribute, :string, limit: 128
    change_column :institutions, :saml_idp_entity_id, :string, limit: 4096
    change_column :institutions, :google_analytics_measurement_id, :string, limit: 1024
    change_column :institutions, :saml_sp_public_cert, :string, limit: 4096
    change_column :institutions, :saml_sp_private_key, :string, limit: 4096
    change_column :institutions, :deposit_form_disagreement_help, :string, limit: 4096
    change_column :institutions, :deposit_form_collection_help, :string, limit: 4096
    change_column :institutions, :deposit_form_access_help, :string, limit: 4096
    change_column :institutions, :saml_sp_next_public_cert, :string, limit: 4096
    change_column :institutions, :saml_idp_signing_cert2, :string, limit: 4096
    change_column :institutions, :saml_idp_encryption_cert, :string, limit: 4096
    change_column :institutions, :saml_idp_encryption_cert2, :string, limit: 4096
    change_column :institutions, :saml_idp_sso_binding_urn, :string, limit: 128
    change_column :institutions, :saml_idp_sso_redirect_service_url, :string, limit: 4096
    change_column :institutions, :saml_metadata_url, :string, limit: 4096
    change_column :institutions, :saml_sp_entity_id, :string, limit: 4096

    change_column :invitees, :email, :string, limit: 1024
    change_column :invitees, :purpose, :string, limit: 1024
    change_column :invitees, :approval_state, :string, limit: 32
    change_column :invitees, :rejection_reason, :string, limit: 1024

    change_column :items, :stage_reason, :string, limit: 4096
    change_column :items, :temp_embargo_expires_at, :string, limit: 128
    change_column :items, :temp_embargo_reason, :string, limit: 4096
    change_column :items, :temp_embargo_type, :string, limit: 32
    change_column :items, :deposit_agreement, :string, limit: 32768
    change_column :items, :previous_stage_reason, :string, limit: 4096

    change_column :logins, :ip_address, :string, limit: 128
    change_column :logins, :auth_hash, :string, limit: 65536
    change_column :logins, :hostname, :string, limit: 1024

    change_column :metadata_profiles, :name, :string, limit: 1024

    change_column :prebuilt_search_elements, :term, :string, limit: 1024

    change_column :prebuilt_searches, :name, :string, limit: 1024

    change_column :registered_elements, :name, :string, limit: 128
    change_column :registered_elements, :scope_note, :string, limit: 1024
    change_column :registered_elements, :uri, :string, limit: 4096
    change_column :registered_elements, :label, :string, limit: 128
    change_column :registered_elements, :input_type, :string, limit: 32
    change_column :registered_elements, :highwire_mapping, :string, limit: 32
    change_column :registered_elements, :dublin_core_mapping, :string, limit: 32

    change_column :settings, :key, :string, limit: 128
    change_column :settings, :value, :string, limit: 4096

    change_column :submission_profile_elements, :help_text, :string, limit: 1024
    change_column :submission_profile_elements, :placeholder_text, :string, limit: 128

    change_column :submission_profiles, :name, :string, limit: 1024

    change_column :tasks, :name, :string, limit: 128
    change_column :tasks, :status_text, :string, limit: 1024
    change_column :tasks, :detail, :string, limit: 65536
    change_column :tasks, :backtrace, :string, limit: 65536
    change_column :tasks, :job_id, :string, limit: 64
    change_column :tasks, :queue, :string, limit: 32

    change_column :units, :title, :string, limit: 1024
    change_column :units, :short_description, :string, limit: 8192
    change_column :units, :introduction, :string, limit: 16384
    change_column :units, :rights, :string, limit: 16384

    change_column :user_groups, :name, :string, limit: 1024
    change_column :user_groups, :key, :string, limit: 128

    change_column :users, :name, :string, limit: 1024
    change_column :users, :email, :string, limit: 1024

    change_column :vocabularies, :name, :string, limit: 1024

    change_column :vocabulary_terms, :stored_value, :string, limit: 1024
    change_column :vocabulary_terms, :displayed_value, :string, limit: 1024
  end
end
