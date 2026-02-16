class CreateReminders < ActiveRecord::Migration[8.1]
  def change
    create_table :reminders, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :book_borrow, null: false, foreign_key: true, type: :uuid, index: false
      t.string :reminder_type, null: false
      t.date :scheduled_for, null: false
      t.datetime :sent_at
      t.timestamps
    end

    add_index :reminders, [:book_borrow_id, :reminder_type], unique: true
    add_index :reminders, [:scheduled_for, :sent_at]
  end
end
