module Library
  class RegisterReader < LibraryCommand
    attr_accessor :serial_number, :email, :full_name

    validates :serial_number, presence: true
    validates :email, presence: true
    validates :full_name, presence: true

    private

    def run
      return validation_failure unless valid?

      reader = Reader.create!(
        serial_number: serial_number,
        email: email,
        full_name: full_name
      )

      Library::Result.new(
        data: Library::ReaderBlueprint.render_as_hash(reader),
        status: :created
      )
    end

    def validation_failure
      Library::Result.new(status: :unprocessable, errors: errors.to_hash)
    end
  end
end
