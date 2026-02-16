module Library
  class ReturnBook < LibraryCommand
    attr_accessor :book_id

    validates :book_id, presence: true

    private

    def run
      return validation_failure unless valid?

      book = Book.find(book_id)
      active_borrow = book.active_borrow

      unless active_borrow
        return Library::Result.new(
          status: :unprocessable,
          errors: {base: "Book is not currently borrowed"}
        )
      end

      active_borrow.update!(return_date: Date.current)

      returned_borrow = BookBorrow.with_reader.find(active_borrow.id)

      Library::Result.new(
        data: Library::BookBorrowBlueprint.render_as_hash(returned_borrow)
      )
    end

    def validation_failure
      Library::Result.new(status: :unprocessable, errors: errors.to_hash)
    end
  end
end
