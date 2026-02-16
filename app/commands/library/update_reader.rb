module Library
  class UpdateReader < LibraryCommand
    attr_accessor :id, :serial_number, :email, :full_name

    validates :id, presence: true

    private

    def run
      return validation_failure unless valid?

      reader = Reader.find(id)
      attrs = {}
      attrs[:serial_number] = serial_number if serial_number.present?
      attrs[:email] = email if email.present?
      attrs[:full_name] = full_name if full_name.present?

      reader.update!(attrs) if attrs.any?

      Library::Result.new(
        data: Library::ReaderBlueprint.render_as_hash(reader.reload)
      )
    end

    def validation_failure
      Library::Result.new(status: :unprocessable, errors: errors.to_hash)
    end
  end
end
