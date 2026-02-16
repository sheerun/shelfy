class LibraryCommand
  include ActiveModel::Model

  def execute
    ActiveRecord::Base.transaction do
      run
    end
  rescue ActiveRecord::RecordNotUnique => e
    handle_not_unique(e)
  rescue ActiveRecord::RecordInvalid => e
    handle_record_invalid(e)
  rescue ActiveRecord::RecordNotFound
    Library::Result.new(status: :not_found, errors: {base: "Record not found"})
  rescue ActiveRecord::InvalidForeignKey
    Library::Result.new(status: :unprocessable, errors: {base: "Invalid reference"})
  end

  private

  def run
    raise NotImplementedError, "Subclasses must implement #run"
  end

  def handle_not_unique(exception)
    field = extract_unique_field(exception.message)
    errors = field ? {field => "has already been taken"} : {base: "Duplicate record"}
    Library::Result.new(status: :unprocessable, errors: errors)
  end

  def handle_record_invalid(exception)
    record_errors = exception.record.errors.to_hash
    Library::Result.new(status: :unprocessable, errors: record_errors)
  end

  def extract_unique_field(message)
    if message =~ /unique.*index.*?_(\w+)$/i
      $1.to_sym
    end
  end
end
