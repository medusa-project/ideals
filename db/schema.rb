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

ActiveRecord::Schema[7.0].define(version: 2022_10_13_183101) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.bigint "length"
    t.bigint "item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "original_filename"
    t.string "medusa_uuid"
    t.string "medusa_key"
    t.string "dspace_id"
    t.boolean "submitted_for_ingest", default: false, null: false
    t.integer "role", default: 0, null: false
    t.integer "bundle", default: 0, null: false
    t.string "permanent_key"
    t.text "description"
    t.boolean "primary", default: false, null: false
    t.datetime "full_text_checked_at"
    t.integer "bundle_position", default: 0, null: false
    t.index ["bundle"], name: "index_bitstreams_on_bundle"
    t.index ["full_text_checked_at"], name: "index_bitstreams_on_full_text_checked_at"
    t.index ["item_id"], name: "index_bitstreams_on_item_id"
    t.index ["medusa_key"], name: "index_bitstreams_on_medusa_key", unique: true
    t.index ["medusa_uuid"], name: "index_bitstreams_on_medusa_uuid"
    t.index ["original_filename"], name: "index_bitstreams_on_original_filename"
    t.index ["permanent_key"], name: "index_bitstreams_on_permanent_key"
    t.index ["primary"], name: "index_bitstreams_on_primary"
    t.index ["staging_key"], name: "index_bitstreams_on_staging_key", unique: true
  end

  create_table "collection_item_memberships", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.bigint "item_id", null: false
    t.boolean "primary", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "item_id"], name: "index_collection_item_memberships_on_collection_id_and_item_id", unique: true
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
    t.index ["buried"], name: "index_collections_on_buried"
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
    t.integer "temp_stat_id"
    t.index ["bitstream_id"], name: "index_events_on_bitstream_id"
    t.index ["event_type"], name: "index_events_on_event_type"
    t.index ["happened_at"], name: "index_events_on_happened_at"
    t.index ["item_id"], name: "index_events_on_item_id"
    t.index ["temp_stat_id"], name: "index_events_on_temp_stat_id"
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
    t.integer "status", default: 0, null: false
    t.float "percent_complete", default: 0.0, null: false
    t.text "files"
    t.text "imported_items"
    t.string "last_error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "kind"
    t.bigint "institution_id", null: false
    t.index ["collection_id"], name: "index_imports_on_collection_id"
    t.index ["institution_id"], name: "index_imports_on_institution_id"
    t.index ["kind"], name: "index_imports_on_kind"
    t.index ["status"], name: "index_imports_on_status"
    t.index ["user_id"], name: "index_imports_on_user_id"
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
    t.string "org_dn", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "fqdn", null: false
    t.boolean "default", default: false, null: false
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
    t.index ["default"], name: "index_institutions_on_default"
    t.index ["fqdn"], name: "index_institutions_on_fqdn", unique: true
    t.index ["key"], name: "index_institutions_on_key", unique: true
    t.index ["name"], name: "index_institutions_on_name", unique: true
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
    t.index ["stage"], name: "index_items_on_stage"
    t.index ["submitter_id"], name: "index_items_on_submitter_id"
  end

  create_table "local_identities", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest"
    t.string "activation_digest"
    t.boolean "activated", default: false
    t.string "reset_digest"
    t.bigint "invitee_id"
    t.datetime "reset_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "activated_at"
    t.string "registration_digest"
    t.string "name", null: false
    t.index ["email"], name: "index_local_identities_on_email", unique: true
    t.index ["invitee_id"], name: "index_local_identities_on_invitee_id"
  end

  create_table "manager_groups", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.bigint "user_group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "user_group_id"], name: "index_manager_groups_on_collection_id_and_user_group_id", unique: true
  end

  create_table "managers", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "collection_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "user_id"], name: "index_managers_on_collection_id_and_user_id", unique: true
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
    t.index ["bitstream_id"], name: "index_messages_on_bitstream_id"
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
    t.boolean "default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "institution_id", null: false
    t.integer "full_text_relevance_weight", default: 5, null: false
    t.index ["default"], name: "index_metadata_profiles_on_default"
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

  create_table "registered_elements", force: :cascade do |t|
    t.string "name", null: false
    t.text "scope_note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uri"
    t.string "label", null: false
    t.bigint "institution_id", null: false
    t.string "vocabulary_key"
    t.string "input_type"
    t.string "highwire_mapping"
    t.index ["institution_id"], name: "index_registered_elements_on_institution_id"
    t.index ["name", "institution_id"], name: "index_registered_elements_on_name_and_institution_id", unique: true
    t.index ["uri", "institution_id"], name: "index_registered_elements_on_uri_and_institution_id", unique: true
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
    t.boolean "default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "institution_id", null: false
    t.index ["default"], name: "index_submission_profiles_on_default"
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

  create_table "submitters", force: :cascade do |t|
    t.bigint "collection_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "user_id"], name: "index_submitters_on_collection_id_and_user_id", unique: true
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
    t.boolean "unit_default", default: false, null: false
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
    t.string "uid", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type", null: false
    t.string "phone"
    t.bigint "local_identity_id"
    t.string "org_dn"
    t.bigint "affiliation_id"
    t.datetime "last_logged_in_at"
    t.text "auth_hash"
    t.bigint "institution_id"
    t.index ["affiliation_id"], name: "index_users_on_affiliation_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["institution_id"], name: "index_users_on_institution_id"
    t.index ["local_identity_id"], name: "index_users_on_local_identity_id"
    t.index ["name"], name: "index_users_on_name"
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  add_foreign_key "ad_groups", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "affiliations_user_groups", "affiliations", on_update: :cascade, on_delete: :cascade
  add_foreign_key "affiliations_user_groups", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "ascribed_elements", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "ascribed_elements", "registered_elements", on_update: :cascade, on_delete: :restrict
  add_foreign_key "bitstream_authorizations", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "bitstream_authorizations", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "bitstreams", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collection_item_memberships", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collection_item_memberships", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collections", "collections", column: "parent_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "collections", "metadata_profiles", on_update: :cascade, on_delete: :restrict
  add_foreign_key "collections", "submission_profiles", on_update: :cascade, on_delete: :restrict
  add_foreign_key "departments", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "departments", "users", on_update: :cascade, on_delete: :cascade
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
  add_foreign_key "imports", "collections", on_update: :cascade, on_delete: :nullify
  add_foreign_key "imports", "institutions", on_update: :cascade, on_delete: :cascade
  add_foreign_key "imports", "users", on_update: :cascade, on_delete: :nullify
  add_foreign_key "institution_administrators", "institutions", on_update: :cascade, on_delete: :cascade
  add_foreign_key "institution_administrators", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "invitees", "institutions", on_update: :cascade, on_delete: :restrict
  add_foreign_key "invitees", "users", column: "inviting_user_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "items", "users", column: "submitter_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "local_identities", "invitees", on_update: :cascade, on_delete: :cascade
  add_foreign_key "manager_groups", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "manager_groups", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "managers", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "managers", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "messages", "bitstreams", on_update: :cascade, on_delete: :nullify
  add_foreign_key "metadata_profile_elements", "metadata_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "metadata_profile_elements", "registered_elements", on_update: :cascade, on_delete: :restrict
  add_foreign_key "submission_profile_elements", "registered_elements", on_update: :cascade, on_delete: :restrict
  add_foreign_key "submission_profile_elements", "submission_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "submitter_groups", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "submitter_groups", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "submitters", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "submitters", "users", on_update: :cascade, on_delete: :cascade
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
end
