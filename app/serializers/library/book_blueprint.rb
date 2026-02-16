module Library
  class BookBlueprint < Blueprinter::Base
    identifier :id

    fields :serial_number, :title, :author
  end
end
