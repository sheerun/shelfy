module Library
  class GetReader < LibraryQuery
    attr_accessor :id

    validates :id, presence: true

    private

    def run
      return validation_failure unless valid?

      reader = Reader.find(id)

      Library::Result.new(
        data: Library::ReaderBlueprint.render_as_hash(reader)
      )
    end

    def validation_failure
      Library::Result.new(status: :unprocessable, errors: errors.to_hash)
    end
  end
end
