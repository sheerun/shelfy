module Library
  class ReaderBlueprint < Blueprinter::Base
    identifier :id

    fields :serial_number, :email, :full_name
  end
end
