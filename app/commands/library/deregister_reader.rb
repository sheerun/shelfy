module Library
  class DeregisterReader < LibraryCommand
    attr_accessor :id

    validates :id, presence: true

    private

    def run
      return validation_failure unless valid?

      reader = Reader.find(id)
      reader.destroy!

      Library::Result.new(status: :ok)
    end

    def validation_failure
      Library::Result.new(status: :unprocessable, errors: errors.to_hash)
    end
  end
end
