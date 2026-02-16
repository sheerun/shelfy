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

ActiveRecord::Schema[8.1].define(version: 2026_02_16_051337) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "book_borrows", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "book_id", null: false
    t.date "borrow_date", null: false
    t.datetime "created_at", null: false
    t.date "due_date", null: false
    t.uuid "reader_id", null: false
    t.date "return_date"
    t.datetime "updated_at", null: false
    t.index ["book_id", "return_date"], name: "index_book_borrows_on_book_id_and_return_date"
    t.index ["book_id"], name: "index_book_borrows_active_borrow", unique: true, where: "(return_date IS NULL)"
    t.index ["reader_id"], name: "index_book_borrows_on_reader_id"
  end

  create_table "books", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.string "author", null: false
    t.datetime "created_at", null: false
    t.string "serial_number", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["serial_number"], name: "index_books_on_serial_number", unique: true
  end

  create_table "readers", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "full_name", null: false
    t.string "serial_number", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_readers_on_email", unique: true
    t.index ["serial_number"], name: "index_readers_on_serial_number", unique: true
  end

  add_foreign_key "book_borrows", "books"
  add_foreign_key "book_borrows", "readers"
end
