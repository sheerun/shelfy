module Library
  class BorrowBook < LibraryCommand
    attr_accessor :book_id, :reader_id

    validates :book_id, presence: true
    validates :reader_id, presence: true

    private

    def run
      return validation_failure unless valid?

      book = Book.find(book_id)
      Reader.find(reader_id)

      if book.active_borrow.present?
        return Library::Result.new(
          status: :unprocessable,
          errors: {base: "Book is already borrowed"}
        )
      end

      today = Date.current
      borrow = BookBorrow.create!(
        book_id: book_id,
        reader_id: reader_id,
        borrow_date: today,
        due_date: today + BookBorrow::LOAN_PERIOD_DAYS.days
      )

      borrow_with_reader = BookBorrow.with_reader.find(borrow.id)

      Library::Result.new(
        data: Library::BookBorrowBlueprint.render_as_hash(borrow_with_reader),
        status: :created
      )
    end

    def validation_failure
      Library::Result.new(status: :unprocessable, errors: errors.to_hash)
    end
  end
end
