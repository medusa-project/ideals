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

ActiveRecord::Schema.define(version: 2022_01_21_162545) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "ad_groups", force: :cascade do |t|
    t.string "urn"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["urn"], name: "index_ad_groups_on_urn", unique: true
  end

  create_table "ad_groups_user_groups", id: false, force: :cascade do |t|
    t.bigint "ad_group_id", null: false
    t.bigint "user_group_id", null: false
  end

  create_table "ad_groups_users", id: false, force: :cascade do |t|
    t.bigint "ad_group_id", null: false
    t.bigint "user_id", null: false
  end

  create_table "administrator_groups", force: :cascade do |t|
    t.bigint "unit_id", null: false
    t.bigint "user_group_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "administrators", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "unit_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "primary", default: false, null: false
    t.index ["unit_id", "user_id"], name: "index_administrators_on_unit_id_and_user_id", unique: true
    t.index ["unit_id"], name: "index_administrators_on_unit_id"
    t.index ["user_id", "unit_id", "primary"], name: "index_administrators_on_user_id_and_unit_id_and_primary"
    t.index ["user_id"], name: "index_administrators_on_user_id"
  end

  create_table "affiliations", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "key", null: false
    t.index ["key"], name: "index_affiliations_on_key", unique: true
    t.index ["name"], name: "index_affiliations_on_name", unique: true
  end

  create_table "affiliations_user_groups", force: :cascade do |t|
    t.bigint "affiliation_id", null: false
    t.bigint "user_group_id", null: false
  end

  create_table "ascribed_elements", force: :cascade do |t|
    t.text "string", null: false
    t.bigint "registered_element_id", null: false
    t.bigint "item_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "uri"
  end

  create_table "bitstream_authorizations", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "user_group_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "bitstreams", force: :cascade do |t|
    t.string "staging_key"
    t.bigint "length"
    t.bigint "item_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
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
    t.index ["medusa_key"], name: "index_bitstreams_on_medusa_key", unique: true
    t.index ["primary"], name: "index_bitstreams_on_primary"
    t.index ["staging_key"], name: "index_bitstreams_on_staging_key", unique: true
  end

  create_table "collection_item_memberships", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.bigint "item_id", null: false
    t.boolean "primary", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["collection_id", "item_id"], name: "index_collection_item_memberships_on_collection_id_and_item_id", unique: true
  end

  create_table "collections", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "metadata_profile_id"
    t.bigint "submission_profile_id"
    t.bigint "parent_id"
    t.boolean "submissions_reviewed", default: true, null: false
    t.string "title"
    t.text "description"
    t.text "short_description"
    t.text "introduction"
    t.text "rights"
    t.text "provenance"
    t.boolean "buried", default: false, null: false
  end

  create_table "departments", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "user_group_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id"
  end

  create_table "embargoes", force: :cascade do |t|
    t.datetime "expires_at", precision: 6, null: false
    t.boolean "full_access", default: true, null: false
    t.boolean "download", default: true, null: false
    t.bigint "item_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["expires_at"], name: "index_embargoes_on_expires_at"
  end

  create_table "events", force: :cascade do |t|
    t.integer "event_type", null: false
    t.bigint "user_id"
    t.text "description"
    t.text "before_changes"
    t.text "after_changes"
    t.bigint "item_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "bitstream_id"
    t.datetime "happened_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["happened_at"], name: "index_events_on_happened_at"
  end

  create_table "handles", force: :cascade do |t|
    t.serial "suffix", null: false
    t.bigint "unit_id"
    t.bigint "collection_id"
    t.bigint "item_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["suffix"], name: "index_handles_on_suffix", unique: true
  end

  create_table "hosts", force: :cascade do |t|
    t.string "pattern", null: false
    t.bigint "user_group_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "imports", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.bigint "user_id", null: false
    t.integer "status", default: 0, null: false
    t.float "percent_complete", default: 0.0, null: false
    t.text "files"
    t.text "imported_items"
    t.string "last_error_message"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["status"], name: "index_imports_on_status"
  end

  create_table "institutions", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.string "org_dn", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "fqdn", null: false
    t.boolean "default", default: false, null: false
    t.index ["default"], name: "index_institutions_on_default"
    t.index ["fqdn"], name: "index_institutions_on_fqdn", unique: true
    t.index ["key"], name: "index_institutions_on_key", unique: true
    t.index ["name"], name: "index_institutions_on_name", unique: true
  end

  create_table "invitees", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "expires_at", precision: 6, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "note", null: false
    t.string "approval_state", default: "pending", null: false
    t.bigint "inviting_user_id"
    t.index ["email"], name: "index_invitees_on_email", unique: true
  end

  create_table "items", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "submitter_id"
    t.boolean "discoverable", default: false, null: false
    t.integer "stage", default: 0, null: false
    t.index ["discoverable"], name: "index_items_on_discoverable"
    t.index ["stage"], name: "index_items_on_stage"
  end

  create_table "local_identities", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest"
    t.string "activation_digest"
    t.boolean "activated", default: false
    t.string "reset_digest"
    t.bigint "invitee_id"
    t.datetime "reset_sent_at", precision: 6
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "activated_at", precision: 6
    t.string "registration_digest"
    t.string "name", null: false
    t.index ["email"], name: "index_local_identities_on_email", unique: true
  end

  create_table "manager_groups", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.bigint "user_group_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "managers", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "collection_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["collection_id", "user_id"], name: "index_managers_on_collection_id_and_user_id", unique: true
    t.index ["collection_id"], name: "index_managers_on_collection_id"
    t.index ["user_id"], name: "index_managers_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.string "staging_key"
    t.string "target_key"
    t.string "status"
    t.string "medusa_key"
    t.string "medusa_uuid"
    t.datetime "response_time", precision: 6
    t.string "error_text"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "operation", null: false
    t.bigint "bitstream_id"
    t.text "raw_request"
    t.text "raw_response"
  end

  create_table "metadata_profile_elements", force: :cascade do |t|
    t.bigint "metadata_profile_id", null: false
    t.bigint "registered_element_id", null: false
    t.integer "index", null: false
    t.boolean "visible", default: true, null: false
    t.boolean "facetable", default: false, null: false
    t.boolean "searchable", default: false, null: false
    t.boolean "sortable", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["facetable"], name: "index_metadata_profile_elements_on_facetable"
    t.index ["index"], name: "index_metadata_profile_elements_on_index"
    t.index ["searchable"], name: "index_metadata_profile_elements_on_searchable"
    t.index ["sortable"], name: "index_metadata_profile_elements_on_sortable"
    t.index ["visible"], name: "index_metadata_profile_elements_on_visible"
  end

  create_table "metadata_profiles", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "default", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "institution_id", null: false
    t.index ["default"], name: "index_metadata_profiles_on_default"
    t.index ["name"], name: "index_metadata_profiles_on_name", unique: true
  end

  create_table "registered_elements", force: :cascade do |t|
    t.string "name", null: false
    t.text "scope_note"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "uri"
    t.string "label", null: false
    t.bigint "institution_id", null: false
    t.string "vocabulary_key"
    t.string "input_type"
    t.index ["name"], name: "index_registered_elements_on_name", unique: true
    t.index ["uri"], name: "index_registered_elements_on_uri", unique: true
  end

  create_table "submission_profile_elements", force: :cascade do |t|
    t.bigint "submission_profile_id", null: false
    t.bigint "registered_element_id", null: false
    t.integer "index", null: false
    t.text "help_text"
    t.boolean "repeatable", default: false, null: false
    t.boolean "required", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "placeholder_text"
    t.index ["index"], name: "index_submission_profile_elements_on_index"
    t.index ["repeatable"], name: "index_submission_profile_elements_on_repeatable"
    t.index ["required"], name: "index_submission_profile_elements_on_required"
  end

  create_table "submission_profiles", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "default", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "institution_id", null: false
    t.index ["default"], name: "index_submission_profiles_on_default"
    t.index ["name"], name: "index_submission_profiles_on_name", unique: true
  end

  create_table "submitter_groups", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.bigint "user_group_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "submitters", force: :cascade do |t|
    t.bigint "collection_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["collection_id", "user_id"], name: "index_submitters_on_collection_id_and_user_id", unique: true
  end

  create_table "unit_collection_memberships", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.bigint "unit_id", null: false
    t.boolean "unit_default", default: false, null: false
    t.boolean "primary", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["unit_id", "collection_id"], name: "index_unit_collection_memberships_on_unit_id_and_collection_id", unique: true
  end

  create_table "units", force: :cascade do |t|
    t.string "title"
    t.bigint "parent_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "institution_id"
    t.text "short_description"
    t.text "introduction"
    t.text "rights"
    t.boolean "buried", default: false, null: false
  end

  create_table "user_groups", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "key", null: false
    t.index ["key"], name: "index_user_groups_on_key", unique: true
    t.index ["name"], name: "index_user_groups_on_name", unique: true
  end

  create_table "user_groups_users", id: false, force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "user_group_id", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "uid", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "type", null: false
    t.string "phone"
    t.bigint "local_identity_id"
    t.string "org_dn"
    t.bigint "affiliation_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["name"], name: "index_users_on_name"
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  add_foreign_key "ad_groups_user_groups", "ad_groups"
  add_foreign_key "ad_groups_user_groups", "user_groups"
  add_foreign_key "administrator_groups", "units", on_update: :cascade, on_delete: :cascade
  add_foreign_key "administrator_groups", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "administrators", "units", on_update: :cascade, on_delete: :cascade
  add_foreign_key "administrators", "users", on_update: :cascade, on_delete: :cascade
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
  add_foreign_key "embargoes", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "events", "bitstreams", on_update: :cascade, on_delete: :cascade
  add_foreign_key "events", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "events", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "handles", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "handles", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "handles", "units", on_update: :cascade, on_delete: :cascade
  add_foreign_key "hosts", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "imports", "collections", on_update: :cascade, on_delete: :nullify
  add_foreign_key "imports", "users", on_update: :cascade, on_delete: :nullify
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
  add_foreign_key "unit_collection_memberships", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "unit_collection_memberships", "units", on_update: :cascade, on_delete: :cascade
  add_foreign_key "units", "institutions", on_update: :cascade, on_delete: :restrict
  add_foreign_key "units", "units", column: "parent_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "user_groups_users", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_groups_users", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "users", "affiliations", on_update: :cascade, on_delete: :nullify
  add_foreign_key "users", "local_identities", on_update: :cascade, on_delete: :cascade
end
