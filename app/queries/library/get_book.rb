module Library
  class GetBook < LibraryQuery
    attr_accessor :id

    validates :id, presence: true

    private

    def run
      return validation_failure unless valid?

      book = Book.with_borrows.find(id)

      Library::Result.new(
        data: Library::BookBlueprint.render_as_hash(book, view: :with_borrows)
      )
    end

    def validation_failure
      Library::Result.new(status: :unprocessable, errors: errors.to_hash)
    end
  end
end
