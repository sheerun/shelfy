class CreateBookBorrows < ActiveRecord::Migration[8.1]
  def change
    create_table :book_borrows, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :book, null: false, foreign_key: true, type: :uuid, index: false
      t.references :reader, null: false, foreign_key: true, type: :uuid
      t.date :borrow_date, null: false
      t.date :due_date, null: false
      t.date :return_date
      t.timestamps
    end

    add_index :book_borrows, :book_id, unique: true, where: "return_date IS NULL", name: "index_book_borrows_active_borrow"
    add_index :book_borrows, [:book_id, :return_date], name: "index_book_borrows_on_book_id_and_return_date"
  end
end
