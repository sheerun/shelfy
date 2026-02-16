module Library
  class BookBlueprint < Blueprinter::Base
    identifier :id

    fields :serial_number, :title, :author

    view :with_status do
      field :status do |book, _options|
        book.try(:borrow_status) || (book.active_borrow.present? ? "borrowed" : "available")
      end
    end

    view :with_borrows do
      include_view :with_status

      association :book_borrows, blueprint: Library::BookBorrowBlueprint, name: :borrows do |book, _options|
        book.book_borrows.sort_by { |b| [b.borrow_date, b.created_at] }.reverse
      end
    end
  end
end
