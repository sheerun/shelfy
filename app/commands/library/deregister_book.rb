module Library
  class DeregisterBook < LibraryCommand
    attr_accessor :id

    validates :id, presence: true

    private

    def run
      return validation_failure unless valid?

      book = Book.find(id)
      book.destroy!

      Library::Result.new(status: :ok)
    end

    def validation_failure
      Library::Result.new(status: :unprocessable, errors: errors.to_hash)
    end
  end
end
