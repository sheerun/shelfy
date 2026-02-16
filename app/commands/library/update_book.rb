module Library
  class UpdateBook < LibraryCommand
    attr_accessor :id, :serial_number, :title, :author

    validates :id, presence: true

    private

    def run
      return validation_failure unless valid?

      book = Book.find(id)
      attrs = {}
      attrs[:serial_number] = serial_number if serial_number.present?
      attrs[:title] = title if title.present?
      attrs[:author] = author if author.present?

      book.update!(attrs) if attrs.any?

      Library::Result.new(
        data: Library::BookBlueprint.render_as_hash(book.reload)
      )
    end

    def validation_failure
      Library::Result.new(status: :unprocessable, errors: errors.to_hash)
    end
  end
end
