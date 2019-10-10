# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_09_19_200143) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "collection_groups", force: :cascade do |t|
    t.string "title"
    t.integer "parent_group_id"
    t.string "group_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "collections", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "collection_group_id"
  end

  create_table "collections_managers", id: false, force: :cascade do |t|
    t.bigint "manager_id", null: false
    t.bigint "collection_id", null: false
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
    t.integer "invitee_id"
    t.datetime "reset_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invitees", force: :cascade do |t|
    t.string "email", null: false
    t.string "role", default: "guest"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "note"
    t.string "approval_state", default: "pending"
  end

  create_table "items", force: :cascade do |t|
    t.string "title"
    t.string "submitter_email"
    t.string "submitter_auth_provider"
    t.boolean "in_archive"
    t.boolean "withdrawn"
    t.integer "collection_id"
    t.boolean "discoverable"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "managers", force: :cascade do |t|
    t.string "uid"
    t.string "provider"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.string "email"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
  end

end
