module Library
  class ListBooks < LibraryQuery
    attr_accessor :page, :per_page, :status

    MAX_PER_PAGE = 50
    DEFAULT_PER_PAGE = 20
    VALID_STATUSES = %w[borrowed available].freeze

    validate :validate_pagination
    validate :validate_status

    private

    def run
      return validation_failure unless valid?

      normalized_page = normalized_page_number
      normalized_per_page = normalized_per_page_number
      offset = (normalized_page - 1) * normalized_per_page

      books = base_query
      total = Book.from(books.except(:order), :books).count
      paginated = books.offset(offset).limit(normalized_per_page)

      Library::Result.new(
        data: {
          data: Library::BookBlueprint.render_as_hash(paginated, view: :with_status),
          meta: {total: total, page: normalized_page, per_page: normalized_per_page}
        }
      )
    end

    def base_query
      query = Book
        .joins("LEFT JOIN book_borrows ON book_borrows.book_id = books.id AND book_borrows.return_date IS NULL")
        .select(
          "books.*",
          "CASE WHEN book_borrows.id IS NOT NULL THEN 'borrowed' ELSE 'available' END AS borrow_status"
        )
        .order("books.created_at")

      case status&.downcase
      when "borrowed"
        query.where("book_borrows.id IS NOT NULL")
      when "available"
        query.where("book_borrows.id IS NULL")
      else
        query
      end
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

    def validate_status
      if status.present? && !VALID_STATUSES.include?(status.downcase)
        errors.add(:status, "must be one of: #{VALID_STATUSES.join(", ")}")
      end
    end

    def validation_failure
      Library::Result.new(status: :unprocessable, errors: errors.to_hash)
    end
  end
end
