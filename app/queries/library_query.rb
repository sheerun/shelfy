class LibraryQuery
  include ActiveModel::Model

  def execute
    run
  rescue ActiveRecord::RecordNotFound
    Library::Result.new(status: :not_found, errors: {base: "Record not found"})
  end

  private

  def run
    raise NotImplementedError, "Subclasses must implement #run"
  end
end
