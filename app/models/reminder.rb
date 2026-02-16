class Reminder < ApplicationRecord
  TYPES = %w[3_days_warning due_date_alert].freeze

  self.implicit_order_column = "created_at"

  belongs_to :book_borrow

  validates :reminder_type, presence: true, inclusion: {in: TYPES}
  validates :scheduled_for, presence: true
  validates :reminder_type, uniqueness: {scope: :book_borrow_id}

  scope :unsent, -> { where(sent_at: nil) }
  scope :due_on, ->(date) { unsent.where(scheduled_for: ..date) }
  scope :with_borrow, -> { includes(book_borrow: {book: [], reader: []}) }
end
