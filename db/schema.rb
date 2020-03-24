# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_03_24_154748) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "administrators", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "unit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "primary", default: false, null: false
    t.index ["unit_id", "user_id"], name: "index_administrators_on_unit_id_and_user_id", unique: true
    t.index ["unit_id"], name: "index_administrators_on_unit_id"
    t.index ["user_id", "unit_id", "primary"], name: "index_administrators_on_user_id_and_unit_id_and_primary"
    t.index ["user_id"], name: "index_administrators_on_user_id"
  end

  create_table "ascribed_elements", force: :cascade do |t|
    t.text "string", null: false
    t.bigint "registered_element_id", null: false
    t.bigint "collection_id"
    t.bigint "item_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "uri"
  end

  create_table "bitstreams", force: :cascade do |t|
    t.string "key", null: false
    t.bigint "length"
    t.bigint "item_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "media_type", null: false
    t.index ["key"], name: "index_bitstreams_on_key", unique: true
  end

  create_table "collections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "primary_unit_id"
    t.bigint "metadata_profile_id"
    t.bigint "submission_profile_id"
    t.bigint "parent_id"
    t.boolean "unit_default", default: false, null: false
  end

  create_table "collections_items", id: false, force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.bigint "item_id", null: false
    t.index ["collection_id", "item_id"], name: "index_collections_items_on_collection_id_and_item_id", unique: true
  end

  create_table "collections_units", id: false, force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.bigint "unit_id", null: false
    t.index ["collection_id", "unit_id"], name: "index_collections_units_on_collection_id_and_unit_id", unique: true
  end

  create_table "handles", force: :cascade do |t|
    t.string "handle"
    t.integer "resource_type_id"
    t.integer "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "prefix"
    t.integer "suffix"
  end

  create_table "identities", force: :cascade do |t|
    t.string "name"
    t.string "email", null: false
    t.string "password_digest"
    t.string "activation_digest"
    t.boolean "activated", default: false
    t.datetime "activated_at"
    t.string "reset_digest"
    t.bigint "invitee_id"
    t.datetime "reset_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invitees", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "note"
    t.string "approval_state", default: "pending"
  end

  create_table "items", force: :cascade do |t|
    t.boolean "withdrawn", default: false, null: false
    t.boolean "discoverable", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "primary_collection_id"
    t.bigint "submitter_id"
    t.boolean "submitting", default: true, null: false
    t.index ["discoverable"], name: "index_items_on_discoverable"
    t.index ["submitting"], name: "index_items_on_submitting"
    t.index ["withdrawn"], name: "index_items_on_withdrawn"
  end

  create_table "managers", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "collection_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "user_id"], name: "index_managers_on_collection_id_and_user_id", unique: true
    t.index ["collection_id"], name: "index_managers_on_collection_id"
    t.index ["user_id"], name: "index_managers_on_user_id"
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
    t.index ["name"], name: "index_registered_elements_on_name", unique: true
    t.index ["uri"], name: "index_registered_elements_on_uri", unique: true
  end

  create_table "submission_profile_elements", force: :cascade do |t|
    t.bigint "submission_profile_id", null: false
    t.bigint "registered_element_id", null: false
    t.integer "index", null: false
    t.string "label"
    t.text "help_text"
    t.boolean "repeatable", default: false, null: false
    t.boolean "required", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "input_type"
    t.index ["index"], name: "index_submission_profile_elements_on_index"
    t.index ["repeatable"], name: "index_submission_profile_elements_on_repeatable"
    t.index ["required"], name: "index_submission_profile_elements_on_required"
  end

  create_table "submission_profiles", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "default", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["default"], name: "index_submission_profiles_on_default"
    t.index ["name"], name: "index_submission_profiles_on_name", unique: true
  end

  create_table "submitters", force: :cascade do |t|
    t.bigint "collection_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["collection_id", "user_id"], name: "index_submitters_on_collection_id_and_user_id", unique: true
  end

  create_table "units", force: :cascade do |t|
    t.string "title"
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_groups", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_user_groups_on_name", unique: true
  end

  create_table "user_groups_users", id: false, force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "user_group_id", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "uid"
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.string "type"
    t.boolean "sysadmin", default: false, null: false
    t.string "phone"
  end

  add_foreign_key "administrators", "units", on_update: :cascade, on_delete: :cascade
  add_foreign_key "administrators", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "ascribed_elements", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "ascribed_elements", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "ascribed_elements", "registered_elements", on_update: :cascade, on_delete: :restrict
  add_foreign_key "bitstreams", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collections", "collections", column: "parent_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "collections", "metadata_profiles", on_update: :cascade, on_delete: :restrict
  add_foreign_key "collections", "submission_profiles", on_update: :cascade, on_delete: :restrict
  add_foreign_key "collections", "units", column: "primary_unit_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "collections_items", "collections", on_update: :cascade, on_delete: :restrict
  add_foreign_key "collections_items", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collections_units", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collections_units", "units", on_update: :cascade, on_delete: :cascade
  add_foreign_key "items", "collections", column: "primary_collection_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "items", "users", column: "submitter_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "managers", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "managers", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "metadata_profile_elements", "metadata_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "metadata_profile_elements", "registered_elements", on_update: :cascade, on_delete: :restrict
  add_foreign_key "submission_profile_elements", "registered_elements", on_update: :cascade, on_delete: :restrict
  add_foreign_key "submission_profile_elements", "submission_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "submitters", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "submitters", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "units", "units", column: "parent_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "user_groups_users", "user_groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_groups_users", "users", on_update: :cascade, on_delete: :cascade
end
