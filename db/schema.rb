# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20151209155645) do

  create_table "alternative_codes", force: :cascade do |t|
    t.text     "content"
    t.integer  "project_file_id"
    t.integer  "start_line"
    t.integer  "start_column"
    t.integer  "end_line"
    t.integer  "end_column"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "created_by"
  end

  add_index "alternative_codes", ["project_file_id"], name: "index_alternative_codes_on_project_file_id"

  create_table "comment_locations", force: :cascade do |t|
    t.integer  "comment_id"
    t.integer  "project_file_id"
    t.integer  "start_line"
    t.integer  "start_column"
    t.integer  "end_line"
    t.integer  "end_column"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "comment_locations", ["comment_id"], name: "index_comment_locations_on_comment_id"
  add_index "comment_locations", ["project_file_id"], name: "index_comment_locations_on_project_file_id"

  create_table "comments", force: :cascade do |t|
    t.text     "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "project_id"
    t.integer  "created_by"
  end

  create_table "project_files", force: :cascade do |t|
    t.string   "name"
    t.integer  "added_by"
    t.integer  "project_id"
    t.integer  "size"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.text     "content"
    t.boolean  "is_directory"
    t.integer  "directory_id"
  end

  add_index "project_files", ["directory_id"], name: "index_project_files_on_directory_id"
  add_index "project_files", ["project_id"], name: "index_project_files_on_project_id"

  create_table "project_permissions", force: :cascade do |t|
    t.integer  "project_id"
    t.integer  "user_id"
    t.boolean  "can_author",   default: false
    t.boolean  "can_view",     default: false
    t.boolean  "can_annotate", default: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "user_email"
  end

  add_index "project_permissions", ["project_id", "user_email"], name: "index_project_permissions_on_project_id_and_user_email", unique: true
  add_index "project_permissions", ["project_id", "user_id"], name: "index_project_permissions_on_project_id_and_user_id", unique: true
  add_index "project_permissions", ["project_id"], name: "index_project_permissions_on_project_id"
  add_index "project_permissions", ["user_id"], name: "index_project_permissions_on_user_id"

  create_table "projects", force: :cascade do |t|
    t.string   "name"
    t.integer  "created_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "password_digest"
    t.string   "activation_digest"
    t.boolean  "activated"
    t.datetime "activated_at"
    t.string   "remember_digest"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "reset_digest"
    t.time     "reset_sent_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true

end
