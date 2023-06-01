# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_06_01_214848) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "ad_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_group_id", null: false
    t.string "name", null: false
    t.index ["user_group_id"], name: "index_ad_groups_on_user_group_id"
  end

  create_table "affiliations", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "key", null: false
    t.index ["key"], name: "index_affiliations_on_key", unique: true
    t.index ["name"], name: "index_affiliations_on_name", unique: true
  end

  create_table "affiliations_user_groups", force: :cascade do |t|
    t.bigint "affiliation_id", null: false
    t.bigint "user_group_id", null: false
    t.index ["affiliation_id", "user_group_id"], name: "aff_ug", unique: true
  end

  create_table "ascribed_elements", force: :cascade do |t|
    t.text "string", null: false
    t.bigint "registered_element_id", null: false
    t.bigint "item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uri"
    t.integer "position", default: 1, null: false
    t.index ["item_id"], name: "index_ascribed_elements_on_item_id"
    t.index ["registered_element_id"], name: "index_ascribed_elements_on_registered_element_id"
  end

  create_table "bitstream_authorizations", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "user_group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id", "user_group_id"], name: "index_bitstream_authorizations_on_item_id_and_user_group_id", unique: true
  end

  create_table "bitstreams", force: :cascade do |t|
    t.string "staging_key"
    t.bigint "length", null: false
    t.bigint "item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "original_filename", null: false
    t.string "medusa_uuid"
    t.string "medusa_key"
    t.integer "role", default: 0, null: false
    t.integer "bundle", default: 0, null: false
    t.string "permanent_key"
    t.text "description"
    t.boolean "primary", default: false, null: false
    t.datetime "full_text_checked_at"
    t.integer "bundle_position"
    t.string "filename", null: false
    t.index ["bundle"], name: "index_bitstreams_on_bundle"
    t.index ["filename"], name: "index_bitstreams_on_filename"
    t.index ["full_text_checked_at"], name: "index_bitstreams_on_full_text_checked_at"
    t.index ["item_id"], name: "index_bitstreams_on_item_id"
    t.index ["length"], name: "index_bitstreams_on_length"
    t.index ["medusa_key"], name: "index_bitstreams_on_medusa_key", unique: true
    t.index ["medusa_uuid"], name: "index_bitstreams_on_medusa_uuid"
    t.index ["original_filename"], name: "index_bitstreams_on_original_filename"
    t.index ["permanent_key"], name: "index_bitstreams_on_permanent_key"
    t.index ["primary"], name: "index_bitstreams_on_primary"
    t.index ["staging_key"], name: "index_bitstreams_on_staging_key", unique: true
  end

  create_table "collection_administrator_groups", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.bigint "user_group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "user_group_id"], name: "index_collection_admin_groups_on_col_id_and_user_group_id", unique: true
  end

  create_table "collection_administrators", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "collection_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "user_id"], name: "index_collection_administrators_on_collection_id_and_user_id", unique: true
  end

  create_table "collection_item_memberships", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.bigint "item_id", null: false
    t.boolean "primary", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "item_id"], name: "index_collection_item_memberships_on_collection_id_and_item_id", unique: true
  end

  create_table "collection_submitters", force: :cascade do |t|
    t.bigint "collection_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "user_id"], name: "index_collection_submitters_on_collection_id_and_user_id", unique: true
  end

  create_table "collections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "metadata_profile_id"
    t.bigint "submission_profile_id"
    t.bigint "parent_id"
    t.boolean "submissions_reviewed", default: false, null: false
    t.string "title"
    t.text "description"
    t.text "short_description"
    t.text "introduction"
    t.text "rights"
    t.text "provenance"
    t.boolean "buried", default: false, null: false
    t.bigint "institution_id", null: false
    t.index ["buried"], name: "index_collections_on_buried"
    t.index ["institution_id"], name: "index_collections_on_institution_id"
    t.index ["metadata_profile_id"], name: "index_collections_on_metadata_profile_id"
    t.index ["parent_id"], name: "index_collections_on_parent_id"
    t.index ["submission_profile_id"], name: "index_collections_on_submission_profile_id"
  end

  create_table "departments", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "user_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_group_id", "user_id"], name: "index_departments_on_user_group_id_and_user_id", unique: true
  end

  create_table "deposit_agreement_question_responses", force: :cascade do |t|
    t.bigint "deposit_agreement_question_id", null: false
    t.string "text", null: false
    t.integer "position", default: 0, null: false
    t.boolean "success", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deposit_agreement_question_id", "position"], name: "index_daqr_on_saq_position"
    t.index ["deposit_agreement_question_id", "text"], name: "index_daqr_on_saq_text"
    t.index ["deposit_agreement_question_id"], name: "index_daqr_on_saq_id"
  end

  create_table "deposit_agreement_questions", force: :cascade do |t|
    t.bigint "institution_id", null: false
    t.string "text", null: false
    t.string "help_text"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["institution_id", "position"], name: "index_daq_on_institution_id_and_position", unique: true
    t.index ["institution_id", "text"], name: "index_deposit_agreement_questions_on_institution_id_and_text", unique: true
    t.index ["institution_id"], name: "index_deposit_agreement_questions_on_institution_id"
  end

  create_table "downloads", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename"
    t.string "url"
    t.bigint "task_id"
    t.boolean "expired", default: false, null: false
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "institution_id", null: false
    t.index ["institution_id"], name: "index_downloads_on_institution_id"
    t.index ["key"], name: "index_downloads_on_key", unique: true
    t.index ["task_id"], name: "index_downloads_on_task_id"
  end

  create_table "email_patterns", force: :cascade do |t|
    t.bigint "user_group_id", null: false
    t.string "pattern", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_group_id"], name: "index_email_patterns_on_user_group_id"
  end

  create_table "embargoes", force: :cascade do |t|
    t.datetime "expires_at"
    t.bigint "item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "reason"
    t.boolean "perpetual", default: false, null: false
    t.integer "kind", null: false
    t.index ["expires_at"], name: "index_embargoes_on_expires_at"
    t.index ["item_id"], name: "index_embargoes_on_item_id"
    t.index ["kind"], name: "index_embargoes_on_kind"
    t.index ["perpetual"], name: "index_embargoes_on_perpetual"
  end

  create_table "embargoes_user_groups", id: false, force: :cascade do |t|
    t.bigint "embargo_id", null: false
    t.bigint "user_group_id", null: false
    t.index ["embargo_id", "user_group_id"], name: "index_embargoes_user_groups_on_embargo_id_and_user_group_id", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.integer "event_type", null: false
    t.bigint "user_id"
    t.text "description"
    t.text "before_changes"
    t.text "after_changes"
    t.bigint "item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "bitstream_id"
    t.datetime "happened_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["bitstream_id"], name: "index_events_on_bitstream_id"
    t.index ["event_type"], name: "index_events_on_event_type"
    t.index ["happened_at"], name: "index_events_on_happened_at"
    t.index ["item_id"], name: "index_events_on_item_id"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "full_texts", force: :cascade do |t|
    t.bigint "bitstream_id", null: false
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bitstream_id"], name: "index_full_texts_on_bitstream_id", unique: true
  end

  create_table "handles", force: :cascade do |t|
    t.serial "suffix", null: false
    t.bigint "unit_id"
    t.bigint "collection_id"
    t.bigint "item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id"], name: "index_handles_on_collection_id"
    t.index ["item_id"], name: "index_handles_on_item_id"
    t.index ["suffix"], name: "index_handles_on_suffix", unique: true
    t.index ["unit_id"], name: "index_handles_on_unit_id"
  end

  create_table "hosts", force: :cascade do |t|
    t.string "pattern", null: false
    t.bigint "user_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_group_id"], name: "index_hosts_on_user_group_id"
  end

  create_table "imports", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.bigint "user_id", null: false
    t.text "files"
    t.text "imported_items"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "format"
    t.bigint "institution_id", null: false
    t.bigint "task_id"
    t.index ["collection_id"], name: "index_imports_on_collection_id"
    t.index ["format"], name: "index_imports_on_format"
    t.index ["institution_id"], name: "index_imports_on_institution_id"
    t.index ["task_id"], name: "index_imports_on_task_id", unique: true
    t.index ["user_id"], name: "index_imports_on_user_id"
  end

  create_table "index_pages", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "institution_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["institution_id"], name: "index_index_pages_on_institution_id"
    t.index ["name", "institution_id"], name: "index_index_pages_on_name_and_institution_id", unique: true
  end

  create_table "index_pages_registered_elements", id: false, force: :cascade do |t|
    t.bigint "index_page_id", null: false
    t.bigint "registered_element_id", null: false
    t.index ["index_page_id", "registered_element_id"], name: "index_index_pages_r_es_on_index_page_id_and_r_e_id", unique: true
  end

  create_table "institution_administrator_groups", force: :cascade do |t|
    t.bigint "institution_id"
    t.bigint "user_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["institution_id", "user_group_id"], name: "index_ins_admin_groups_on_ins_id_and_user_group_id", unique: true
    t.index ["institution_id"], name: "index_institution_administrator_groups_on_institution_id"
    t.index ["user_group_id"], name: "index_institution_administrator_groups_on_user_group_id"
  end

  create_table "institution_administrators", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "institution_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["institution_id"], name: "index_institution_administrators_on_institution_id"
    t.index ["user_id", "institution_id"], name: "index_institution_administrators_on_user_id_and_institution_id", unique: true
    t.index ["user_id"], name: "index_institution_administrators_on_user_id"
  end

  create_table "institutions", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.string "shibboleth_org_dn"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "fqdn", null: false
    t.string "feedback_email"
    t.string "footer_background_color", default: "#13294b", null: false
    t.string "header_background_color", default: "#13294b", null: false
    t.string "link_color", default: "#23527c", null: false
    t.string "link_hover_color", default: "#23527c", null: false
    t.string "primary_color", default: "#23527c", null: false
    t.string "primary_hover_color", default: "#05325b", null: false
    t.string "header_image_filename"
    t.string "footer_image_filename"
    t.string "main_website_url"
    t.text "welcome_html"
    t.string "active_link_color", default: "#23527c", null: false
    t.string "banner_image_filename"
    t.string "copyright_notice"
    t.string "service_name", null: false
    t.string "about_url"
    t.text "about_html"
    t.integer "medusa_file_group_id"
    t.string "outgoing_message_queue"
    t.string "incoming_message_queue"
    t.boolean "has_favicon", default: false, null: false
    t.integer "latitude_degrees"
    t.integer "latitude_minutes"
    t.float "latitude_seconds"
    t.integer "longitude_degrees"
    t.integer "longitude_minutes"
    t.float "longitude_seconds"
    t.integer "earliest_search_year", default: 2000, null: false
    t.bigint "title_element_id"
    t.bigint "author_element_id"
    t.bigint "description_element_id"
    t.bigint "date_submitted_element_id"
    t.bigint "date_approved_element_id"
    t.bigint "date_published_element_id"
    t.bigint "handle_uri_element_id"
    t.text "deposit_agreement"
    t.integer "banner_image_height", default: 200, null: false
    t.string "saml_idp_sso_service_url"
    t.text "saml_idp_cert"
    t.string "saml_email_attribute"
    t.string "saml_first_name_attribute"
    t.string "saml_last_name_attribute"
    t.integer "sso_federation"
    t.string "saml_idp_entity_id"
    t.integer "saml_email_location"
    t.string "google_analytics_measurement_id"
    t.boolean "local_auth_enabled", default: true, null: false
    t.boolean "saml_auth_enabled", default: false, null: false
    t.boolean "shibboleth_auth_enabled", default: false, null: false
    t.string "shibboleth_email_attribute", default: "mail"
    t.string "shibboleth_name_attribute", default: "displayName"
    t.text "shibboleth_extra_attributes", default: "[]"
    t.index ["fqdn"], name: "index_institutions_on_fqdn", unique: true
    t.index ["incoming_message_queue"], name: "index_institutions_on_incoming_message_queue", unique: true
    t.index ["key"], name: "index_institutions_on_key", unique: true
    t.index ["medusa_file_group_id"], name: "index_institutions_on_medusa_file_group_id", unique: true
    t.index ["name"], name: "index_institutions_on_name", unique: true
    t.index ["outgoing_message_queue"], name: "index_institutions_on_outgoing_message_queue", unique: true
    t.index ["saml_idp_cert"], name: "index_institutions_on_saml_idp_cert", unique: true
    t.index ["saml_idp_entity_id"], name: "index_institutions_on_saml_idp_entity_id", unique: true
    t.index ["saml_idp_sso_service_url"], name: "index_institutions_on_saml_idp_sso_service_url", unique: true
    t.index ["shibboleth_org_dn"], name: "index_institutions_on_shibboleth_org_dn", unique: true
  end

  create_table "invitees", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "note", null: false
    t.string "approval_state", default: "pending", null: false
    t.bigint "inviting_user_id"
    t.bigint "institution_id"
    t.boolean "institution_admin", default: false, null: false
    t.text "rejection_reason"
    t.index ["email"], name: "index_invitees_on_email", unique: true
    t.index ["institution_id"], name: "index_invitees_on_institution_id"
    t.index ["inviting_user_id"], name: "index_invitees_on_inviting_user_id"
  end

  create_table "items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "submitter_id"
    t.integer "stage", default: 0, null: false
    t.text "stage_reason"
    t.string "temp_embargo_expires_at"
    t.text "temp_embargo_reason"
    t.string "temp_embargo_type"
    t.integer "temp_embargo_kind"
    t.bigint "institution_id"
    t.index ["institution_id"], name: "index_items_on_institution_id"
    t.index ["stage"], name: "index_items_on_stage"
    t.index ["submitter_id"], name: "index_items_on_submitter_id"
  end

  create_table "local_identities", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest"
    t.string "reset_digest"
    t.bigint "invitee_id", null: false
    t.datetime "reset_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "registration_digest"
    t.string "lowercase_email", null: false
    t.index ["email"], name: "index_local_identities_on_email", unique: true
    t.index ["invitee_id"], name: "index_local_identities_on_invitee_id"
    t.index ["lowercase_email"], name: "index_local_identities_on_lowercase_email", unique: true
  end

  create_table "logins", force: :cascade do |t|
    t.bigint "user_id"
    t.string "ip_address"
    t.text "auth_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "hostname"
    t.integer "provider"
    t.index ["created_at"], name: "index_logins_on_created_at"
    t.index ["user_id"], name: "index_logins_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.string "staging_key"
    t.string "target_key"
    t.string "status"
    t.string "medusa_key"
    t.string "medusa_uuid"
    t.datetime "response_time"
    t.string "error_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "operation", null: false
    t.bigint "bitstream_id"
    t.text "raw_request"
    t.text "raw_response"
    t.datetime "sent_at"
    t.bigint "institution_id", null: false
    t.index ["bitstream_id"], name: "index_messages_on_bitstream_id"
    t.index ["institution_id"], name: "index_messages_on_institution_id"
  end

  create_table "metadata_profile_elements", force: :cascade do |t|
    t.bigint "metadata_profile_id", null: false
    t.bigint "registered_element_id", null: false
    t.integer "position", null: false
    t.boolean "visible", default: true, null: false
    t.boolean "faceted", default: false, null: false
    t.boolean "searchable", default: false, null: false
    t.boolean "sortable", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "relevance_weight", default: 5, null: false
    t.index ["faceted"], name: "index_metadata_profile_elements_on_faceted"
    t.index ["metadata_profile_id"], name: "index_metadata_profile_elements_on_metadata_profile_id"
    t.index ["position"], name: "index_metadata_profile_elements_on_position"
    t.index ["registered_element_id"], name: "index_metadata_profile_elements_on_registered_element_id"
    t.index ["searchable"], name: "index_metadata_profile_elements_on_searchable"
    t.index ["sortable"], name: "index_metadata_profile_elements_on_sortable"
    t.index ["visible"], name: "index_metadata_profile_elements_on_visible"
  end

  create_table "metadata_profiles", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "institution_default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "institution_id"
    t.integer "full_text_relevance_weight", default: 5, null: false
    t.integer "all_elements_relevance_weight", default: 5, null: false
    t.index ["institution_default"], name: "index_metadata_profiles_on_institution_default"
    t.index ["institution_id", "name"], name: "index_metadata_profiles_on_institution_id_and_name", unique: true
    t.index ["institution_id"], name: "index_metadata_profiles_on_institution_id"
  end

  create_table "monthly_collection_item_download_counts", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.integer "year", null: false
    t.integer "month", null: false
    t.integer "count", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "year", "month"], name: "index_monthly_collection_item_download_counts_unique", unique: true
    t.index ["collection_id"], name: "index_monthly_collection_item_download_counts_on_collection_id"
    t.index ["month"], name: "index_monthly_collection_item_download_counts_on_month"
    t.index ["year"], name: "index_monthly_collection_item_download_counts_on_year"
  end

  create_table "monthly_institution_item_download_counts", force: :cascade do |t|
    t.bigint "institution_id", null: false
    t.integer "year", null: false
    t.integer "month", null: false
    t.integer "count", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["institution_id", "year", "month"], name: "index_monthly_ins_item_download_counts_unique", unique: true
    t.index ["institution_id"], name: "index_monthly_ins_item_download_counts_on_ins_id"
    t.index ["month"], name: "index_monthly_institution_item_download_counts_on_month"
    t.index ["year"], name: "index_monthly_institution_item_download_counts_on_year"
  end

  create_table "monthly_item_download_counts", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.integer "year", null: false
    t.integer "month", null: false
    t.integer "count", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "collection_id", null: false
    t.bigint "unit_id", null: false
    t.bigint "institution_id", null: false
    t.index ["collection_id"], name: "index_monthly_item_download_counts_on_collection_id"
    t.index ["institution_id", "unit_id", "collection_id", "item_id", "year", "month"], name: "index_monthly_item_download_counts_on_model_fks", unique: true
    t.index ["institution_id"], name: "index_monthly_item_download_counts_on_institution_id"
    t.index ["item_id"], name: "index_monthly_item_download_counts_on_item_id"
    t.index ["unit_id"], name: "index_monthly_item_download_counts_on_unit_id"
  end

  create_table "monthly_unit_item_download_counts", force: :cascade do |t|
    t.bigint "unit_id", null: false
    t.integer "year", null: false
    t.integer "month", null: false
    t.integer "count", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["month"], name: "index_monthly_unit_item_download_counts_on_month"
    t.index ["unit_id", "year", "month"], name: "index_monthly_unit_item_download_counts_unique", unique: true
    t.index ["unit_id"], name: "index_monthly_unit_item_download_counts_on_unit_id"
    t.index ["year"], name: "index_monthly_unit_item_download_counts_on_year"
  end

  create_table "prebuilt_search_elements", force: :cascade do |t|
    t.bigint "prebuilt_search_id", null: false
    t.bigint "registered_element_id", null: false
    t.string "term", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["prebuilt_search_id"], name: "index_prebuilt_search_elements_on_prebuilt_search_id"
    t.index ["registered_element_id"], name: "index_prebuilt_search_elements_on_registered_element_id"
  end

  create_table "prebuilt_searches", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "institution_id", null: false
    t.bigint "ordering_element_id"
    t.integer "direction", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["institution_id"], name: "index_prebuilt_searches_on_institution_id"
    t.index ["ordering_element_id"], name: "index_prebuilt_searches_on_ordering_element_id"
  end

  create_table "registered_elements", force: :cascade do |t|
    t.string "name", null: false
    t.text "scope_note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uri"
    t.string "label", null: false
    t.bigint "institution_id"
    t.string "input_type", default: "text_field", null: false
    t.string "highwire_mapping"
    t.bigint "vocabulary_id"
    t.index ["institution_id", "uri"], name: "index_registered_elements_on_institution_id_and_uri", unique: true
    t.index ["institution_id"], name: "index_registered_elements_on_institution_id"
    t.index ["name", "institution_id"], name: "index_registered_elements_on_name_and_institution_id", unique: true
    t.index ["vocabulary_id"], name: "index_registered_elements_on_vocabulary_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "settings", force: :cascade do |t|
    t.string "key"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "submission_profile_elements", force: :cascade do |t|
    t.bigint "submission_profile_id", null: false
    t.bigint "registered_element_id", null: false
    t.integer "position", null: false
    t.text "help_text"
    t.boolean "repeatable", default: false, null: false
    t.boolean "required", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "placeholder_text"
    t.index ["position"], name: "index_submission_profile_elements_on_position"
    t.index ["registered_element_id"], name: "index_submission_profile_elements_on_registered_element_id"
    t.index ["repeatable"], name: "index_submission_profile_elements_on_repeatable"
    t.index ["required"], name: "index_submission_profile_elements_on_required"
    t.index ["submission_profile_id"], name: "index_submission_profile_elements_on_submission_profile_id"
  end

  create_table "submission_profiles", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "institution_default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "institution_id", null: false
    t.index ["institution_default"], name: "index_submission_profiles_on_institution_default"
    t.index ["institution_id", "name"], name: "index_submission_profiles_on_institution_id_and_name", unique: true
    t.index ["institution_id"], name: "index_submission_profiles_on_institution_id"
  end

  create_table "submitter_groups", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.bigint "user_group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "user_group_id"], name: "index_submitter_groups_on_collection_id_and_user_group_id", unique: true
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.string "status_text", null: false
    t.float "percent_complete", default: 0.0, null: false
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.boolean "indeterminate", default: false, null: false
    t.text "detail"
    t.text "backtrace"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "institution_id"
    t.index ["created_at"], name: "index_tasks_on_created_at"
    t.index ["institution_id"], name: "index_tasks_on_institution_id"
    t.index ["started_at"], name: "index_tasks_on_started_at"
    t.index ["status"], name: "index_tasks_on_status"
    t.index ["stopped_at"], name: "index_tasks_on_stopped_at"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "unit_administrator_groups", force: :cascade do |t|
    t.bigint "unit_id", null: false
    t.bigint "user_group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_group_id", "unit_id"], name: "index_unit_administrator_groups_on_user_group_id_and_unit_id", unique: true
  end

  create_table "unit_administrators", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "unit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "primary", default: false, null: false
    t.index ["unit_id", "user_id"], name: "index_unit_administrators_on_unit_id_and_user_id", unique: true
    t.index ["user_id", "unit_id", "primary"], name: "index_unit_administrators_on_user_id_and_unit_id_and_primary"
  end

  create_table "unit_collection_memberships", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.bigint "unit_id", null: false
    t.boolean "primary", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["unit_id", "collection_id"], name: "index_unit_collection_memberships_on_unit_id_and_collection_id", unique: true
  end

  create_table "units", force: :cascade do |t|
    t.string "title"
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "institution_id"
    t.text "short_description"
    t.text "introduction"
    t.text "rights"
    t.boolean "buried", default: false, null: false
    t.bigint "metadata_profile_id"
    t.index ["institution_id"], name: "index_units_on_institution_id"
    t.index ["metadata_profile_id"], name: "index_units_on_metadata_profile_id"
    t.index ["parent_id"], name: "index_units_on_parent_id"
  end

  create_table "user_groups", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "key", null: false
    t.bigint "institution_id"
    t.boolean "defines_institution", default: false
    t.index ["institution_id", "key"], name: "index_user_groups_on_institution_id_and_key", unique: true
    t.index ["institution_id", "name"], name: "index_user_groups_on_institution_id_and_name", unique: true
    t.index ["institution_id"], name: "index_user_groups_on_institution_id"
  end

  create_table "user_groups_users", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "user_group_id", null: false
    t.index ["user_id", "user_group_id"], name: "index_user_groups_users_on_user_id_and_user_group_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone"
    t.bigint "local_identity_id"
    t.bigint "affiliation_id"
    t.bigint "institution_id", null: false
    t.boolean "enabled", default: true, null: false
    t.index ["affiliation_id"], name: "index_users_on_affiliation_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["institution_id"], name: "index_users_on_institution_id"
    t.index ["local_identity_id"], name: "index_users_on_local_identity_id"
    t.index ["name"], name: "index_users_on_name"
  end

  create_table "vocabularies", force: :cascade do |t|
    t.bigint "institution_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["institution_id", "name"], name: "index_vocabularies_on_institution_id_and_name", unique: true
  end

  create_table "vocabulary_terms", force: :cascade do |t|
    t.bigint "vocabulary_id", null: false
    t.string "stored_value", null: false
    t.string "displayed_value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vocabulary_id", "displayed_value"], name: "index_vocabulary_terms_on_vocabulary_id_and_displayed_value", unique: true
    t.index ["vocabulary_id", "stored_value"], name: "index_vocabulary_terms_on_vocabulary_id_and_stored_value", unique: true
    t.index ["vocabulary_id"], name: "index_vocabulary_terms_on_vocabulary_id"
  end

  add_foreign_key "ad_groups", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "affiliations_user_groups", "affiliations", on_update: :cascade, on_delete: :cascade
  add_foreign_key "affiliations_user_groups", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "ascribed_elements", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "ascribed_elements", "registered_elements", on_update: :cascade, on_delete: :restrict
  add_foreign_key "bitstream_authorizations", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "bitstream_authorizations", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "bitstreams", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collection_administrator_groups", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collection_administrator_groups", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collection_administrators", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collection_administrators", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collection_item_memberships", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collection_item_memberships", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collection_submitters", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collection_submitters", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collections", "collections", column: "parent_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "collections", "institutions", on_update: :cascade, on_delete: :restrict
  add_foreign_key "collections", "metadata_profiles", on_update: :cascade, on_delete: :nullify
  add_foreign_key "collections", "submission_profiles", on_update: :cascade, on_delete: :nullify
  add_foreign_key "departments", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "departments", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "deposit_agreement_question_responses", "deposit_agreement_questions", on_update: :cascade, on_delete: :cascade
  add_foreign_key "deposit_agreement_questions", "institutions", on_update: :cascade, on_delete: :cascade
  add_foreign_key "downloads", "institutions", on_update: :cascade, on_delete: :cascade
  add_foreign_key "downloads", "tasks", on_update: :cascade, on_delete: :nullify
  add_foreign_key "email_patterns", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "embargoes", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "embargoes_user_groups", "embargoes", on_update: :cascade, on_delete: :cascade
  add_foreign_key "embargoes_user_groups", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "events", "bitstreams", on_update: :cascade, on_delete: :cascade
  add_foreign_key "events", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "events", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "full_texts", "bitstreams", on_update: :cascade, on_delete: :cascade
  add_foreign_key "handles", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "handles", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "handles", "units", on_update: :cascade, on_delete: :cascade
  add_foreign_key "hosts", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "imports", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "imports", "institutions", on_update: :cascade, on_delete: :cascade
  add_foreign_key "imports", "tasks", on_update: :cascade, on_delete: :restrict
  add_foreign_key "imports", "users", on_update: :cascade, on_delete: :nullify
  add_foreign_key "institution_administrators", "institutions", on_update: :cascade, on_delete: :cascade
  add_foreign_key "institution_administrators", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "institutions", "registered_elements", column: "author_element_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "institutions", "registered_elements", column: "date_approved_element_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "institutions", "registered_elements", column: "date_published_element_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "institutions", "registered_elements", column: "date_submitted_element_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "institutions", "registered_elements", column: "description_element_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "institutions", "registered_elements", column: "handle_uri_element_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "institutions", "registered_elements", column: "title_element_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "invitees", "institutions", on_update: :cascade, on_delete: :cascade
  add_foreign_key "invitees", "users", column: "inviting_user_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "items", "institutions", on_update: :cascade, on_delete: :restrict
  add_foreign_key "items", "users", column: "submitter_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "local_identities", "invitees", on_update: :cascade, on_delete: :cascade
  add_foreign_key "logins", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "messages", "bitstreams", on_update: :cascade, on_delete: :nullify
  add_foreign_key "messages", "institutions", on_update: :cascade, on_delete: :cascade
  add_foreign_key "metadata_profile_elements", "metadata_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "metadata_profile_elements", "registered_elements", on_update: :cascade, on_delete: :cascade
  add_foreign_key "prebuilt_search_elements", "prebuilt_searches", on_update: :cascade, on_delete: :cascade
  add_foreign_key "prebuilt_search_elements", "registered_elements", on_update: :cascade, on_delete: :restrict
  add_foreign_key "prebuilt_searches", "institutions", on_update: :cascade, on_delete: :cascade
  add_foreign_key "prebuilt_searches", "registered_elements", column: "ordering_element_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "registered_elements", "institutions", on_update: :cascade, on_delete: :cascade
  add_foreign_key "registered_elements", "vocabularies", on_update: :cascade, on_delete: :restrict
  add_foreign_key "submission_profile_elements", "registered_elements", on_update: :cascade, on_delete: :cascade
  add_foreign_key "submission_profile_elements", "submission_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "submitter_groups", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "submitter_groups", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks", "institutions", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks", "users", on_update: :cascade, on_delete: :nullify
  add_foreign_key "unit_administrator_groups", "units", on_update: :cascade, on_delete: :cascade
  add_foreign_key "unit_administrator_groups", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "unit_administrators", "units", on_update: :cascade, on_delete: :cascade
  add_foreign_key "unit_administrators", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "unit_collection_memberships", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "unit_collection_memberships", "units", on_update: :cascade, on_delete: :cascade
  add_foreign_key "units", "institutions", on_update: :cascade, on_delete: :restrict
  add_foreign_key "units", "metadata_profiles", on_update: :cascade, on_delete: :restrict
  add_foreign_key "units", "units", column: "parent_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "user_groups", "institutions", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_groups_users", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_groups_users", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "users", "affiliations", on_update: :cascade, on_delete: :nullify
  add_foreign_key "users", "institutions", on_update: :cascade, on_delete: :restrict
  add_foreign_key "users", "local_identities", on_update: :cascade, on_delete: :cascade
  add_foreign_key "vocabularies", "institutions", on_update: :cascade, on_delete: :cascade
  add_foreign_key "vocabulary_terms", "vocabularies", on_update: :cascade, on_delete: :cascade
end
