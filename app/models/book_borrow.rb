class BookBorrow < ApplicationRecord
  LOAN_PERIOD_DAYS = 30

  self.implicit_order_column = "created_at"

  belongs_to :book
  belongs_to :reader

  validates :borrow_date, presence: true
  validates :due_date, presence: true
  validates :book_id, uniqueness: {conditions: -> { where(return_date: nil) }, message: "already has an active borrow"}

  scope :active, -> { where(return_date: nil) }
  scope :returned, -> { where.not(return_date: nil) }
  scope :most_recent_first, -> { order(borrow_date: :desc, created_at: :desc) }

  scope :with_reader, -> { includes(:reader) }
end
