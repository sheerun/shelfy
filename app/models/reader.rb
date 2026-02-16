class Reader < ApplicationRecord
  self.implicit_order_column = "created_at"

  has_many :book_borrows, dependent: :destroy

  validates :serial_number, presence: true,
    format: {with: /\A\d{6}\z/, message: "must be a six-digit number"},
    uniqueness: true
  validates :email, presence: true, uniqueness: true,
    format: {with: URI::MailTo::EMAIL_REGEXP, message: "is not a valid email address"}
  validates :full_name, presence: true
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
