module Library
  class ListReaders < LibraryQuery
    attr_accessor :page, :per_page

    MAX_PER_PAGE = 50
    DEFAULT_PER_PAGE = 20

    validate :validate_pagination

    private

    def run
      return validation_failure unless valid?

      normalized_page = normalized_page_number
      normalized_per_page = normalized_per_page_number
      offset = (normalized_page - 1) * normalized_per_page

      readers = Reader.order(:created_at)
      total = readers.count
      paginated = readers.offset(offset).limit(normalized_per_page)

      Library::Result.new(
        data: {
          data: Library::ReaderBlueprint.render_as_hash(paginated),
          meta: {total: total, page: normalized_page, per_page: normalized_per_page}
        }
      )
    end

    def normalized_page_number
      p = page.to_i
      (p < 1) ? 1 : p
    end

    def normalized_per_page_number
      pp = per_page.to_i
      return DEFAULT_PER_PAGE if pp < 1
      [pp, MAX_PER_PAGE].min
    end

    def validate_pagination
      if page.present? && page.to_s !~ /\A\d+\z/
        errors.add(:page, "must be a positive integer")
      end
      if per_page.present? && per_page.to_s !~ /\A\d+\z/
        errors.add(:per_page, "must be a positive integer")
      end
    end

    def validation_failure
      Library::Result.new(status: :unprocessable, errors: errors.to_hash)
    end
  end
end
