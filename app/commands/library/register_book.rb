module Library
  class RegisterBook < LibraryCommand
    attr_accessor :serial_number, :title, :author

    validates :serial_number, presence: true
    validates :title, presence: true
    validates :author, presence: true

    private

    def run
      return validation_failure unless valid?

      book = Book.create!(
        serial_number: serial_number,
        title: title,
        author: author
      )

      Library::Result.new(
        data: Library::BookBlueprint.render_as_hash(book),
        status: :created
      )
    end

    def validation_failure
      Library::Result.new(status: :unprocessable, errors: errors.to_hash)
    end
  end
end
