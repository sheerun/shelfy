module Library
  class BookBorrowBlueprint < Blueprinter::Base
    field :reader_card_number do |borrow, _options|
      borrow.reader.serial_number
    end

    field :reader_email do |borrow, _options|
      borrow.reader.email
    end

    fields :borrow_date, :due_date, :return_date
  end
end
