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

ActiveRecord::Schema.define(version: 2017_03_01_033802) do

  create_table "alternative_codes", force: :cascade do |t|
    t.text "content"
    t.integer "project_file_id"
    t.integer "start_line"
    t.integer "start_column"
    t.integer "end_line"
    t.integer "end_column"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.index ["project_file_id"], name: "index_alternative_codes_on_project_file_id"
  end

  create_table "comment_locations", force: :cascade do |t|
    t.integer "comment_id"
    t.integer "project_file_id"
    t.integer "start_line"
    t.integer "start_column"
    t.integer "end_line"
    t.integer "end_column"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comment_id"], name: "index_comment_locations_on_comment_id"
    t.index ["project_file_id"], name: "index_comment_locations_on_project_file_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "project_id"
    t.integer "created_by"
  end

  create_table "project_files", force: :cascade do |t|
    t.string "name"
    t.integer "added_by"
    t.integer "project_id"
    t.integer "size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "content"
    t.boolean "is_directory"
    t.integer "directory_id"
    t.index ["directory_id"], name: "index_project_files_on_directory_id"
    t.index ["project_id", "name", "directory_id"], name: "index_project_files_on_project_id_and_name_and_directory_id", unique: true
    t.index ["project_id"], name: "index_project_files_on_project_id"
  end

  create_table "project_permissions", force: :cascade do |t|
    t.integer "project_id"
    t.integer "user_id"
    t.boolean "can_author", default: false
    t.boolean "can_view", default: false
    t.boolean "can_annotate", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_email"
    t.index ["project_id", "user_email"], name: "index_project_permissions_on_project_id_and_user_email", unique: true
    t.index ["project_id", "user_id"], name: "index_project_permissions_on_project_id_and_user_id", unique: true
    t.index ["project_id"], name: "index_project_permissions_on_project_id"
    t.index ["user_id"], name: "index_project_permissions_on_user_id"
  end

  create_table "project_tags", force: :cascade do |t|
    t.integer "tag_id"
    t.integer "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id", "project_id"], name: "index_project_tags_on_tag_id_and_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.integer "created_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "public_links", force: :cascade do |t|
    t.string "link_uuid"
    t.integer "project_id"
    t.string "name"
    t.index ["link_uuid"], name: "index_public_links_on_link_uuid", unique: true
    t.index ["project_id"], name: "index_public_links_on_project_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "text"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["text", "user_id"], name: "index_tags_on_text_and_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "password_digest"
    t.string "activation_digest"
    t.boolean "activated"
    t.datetime "activated_at"
    t.string "remember_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reset_digest"
    t.datetime "reset_sent_at"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "alternative_codes", "project_files"
  add_foreign_key "comment_locations", "comments"
  add_foreign_key "comment_locations", "project_files"
  add_foreign_key "project_files", "projects"
  add_foreign_key "project_permissions", "projects"
  add_foreign_key "project_permissions", "users"
  add_foreign_key "project_tags", "projects"
  add_foreign_key "public_links", "projects"
  add_foreign_key "tags", "users"
end
