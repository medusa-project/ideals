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

ActiveRecord::Schema.define(version: 2020_02_05_210036) do

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

  create_table "assignments", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_assignments_on_role_id"
    t.index ["user_id"], name: "index_assignments_on_user_id"
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

  create_table "collection_unit_relationships", force: :cascade do |t|
    t.bigint "collection_id"
    t.bigint "unit_id"
    t.boolean "primary", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["unit_id", "primary"], name: "index_collection_units_on_unit_id_and_primary"
  end

  create_table "collections", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "item_collection_relationships", force: :cascade do |t|
    t.bigint "collection_id"
    t.bigint "item_id"
    t.boolean "primary", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["collection_id", "primary"], name: "index_item_collections_on_collection_id_and_primary"
  end

  create_table "items", force: :cascade do |t|
    t.string "title"
    t.string "submitter_email"
    t.string "submitter_auth_provider"
    t.boolean "in_archive"
    t.boolean "withdrawn"
    t.boolean "discoverable"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "registered_elements", force: :cascade do |t|
    t.string "name", null: false
    t.text "scope_note"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_registered_elements_on_name", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "users", force: :cascade do |t|
    t.string "uid"
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.string "type"
  end

  add_foreign_key "administrators", "units", on_update: :cascade, on_delete: :cascade
  add_foreign_key "administrators", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "assignments", "roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "assignments", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "bitstreams", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collection_unit_relationships", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collection_unit_relationships", "units", on_update: :cascade, on_delete: :restrict
  add_foreign_key "item_collection_relationships", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "item_collection_relationships", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "managers", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "managers", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "submitters", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "submitters", "users", on_update: :cascade, on_delete: :cascade
end
