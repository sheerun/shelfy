class Book < ApplicationRecord
  self.implicit_order_column = "created_at"

  has_many :book_borrows, dependent: :destroy
  has_one :active_borrow, -> { where(return_date: nil) }, class_name: "BookBorrow"

  scope :with_borrows, -> { includes(book_borrows: :reader) }
  scope :with_borrow_status, -> {
    left_joins(:book_borrows)
      .select("books.*, CASE WHEN book_borrows.id IS NOT NULL AND book_borrows.return_date IS NULL THEN 'borrowed' ELSE 'available' END AS borrow_status")
      .group("books.id, book_borrows.id, book_borrows.return_date")
  }

  validates :serial_number, presence: true,
    format: {with: /\A\d{6}\z/, message: "must be a six-digit number"},
    uniqueness: true
  validates :title, presence: true
  validates :author, presence: true
  validate :serial_number_in_range

  private

  def serial_number_in_range
    return unless serial_number.present? && serial_number.match?(/\A\d{6}\z/)
    number = serial_number.to_i
    unless number.between?(100_000, 999_999)
      errors.add(:serial_number, "must be between 100000 and 999999")
    end
  end
end
