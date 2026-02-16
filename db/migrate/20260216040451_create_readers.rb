class CreateReaders < ActiveRecord::Migration[8.1]
  def change
    create_table :readers, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.string :serial_number, null: false
      t.string :email, null: false
      t.string :full_name, null: false

      t.timestamps
    end
    add_index :readers, :serial_number, unique: true
    add_index :readers, :email, unique: true
  end
end
