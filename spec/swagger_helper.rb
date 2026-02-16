require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("public").to_s

  config.openapi_specs = {
    "docs/openapi.json" => {
      openapi: "3.0.3",
      info: {
        title: "Shelfy API",
        version: "v1",
        description: "API documentation for the Shelfy library management system"
      },
      servers: [
        {
          url: "{protocol}://{host}",
          variables: {
            protocol: {default: "http", enum: ["http", "https"]},
            host: {default: "localhost:3000"}
          }
        }
      ],
      paths: {},
      components: {
        schemas: {
          Reader: {
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              serial_number: {type: :string, example: "100001"},
              email: {type: :string, format: :email, example: "reader@example.com"},
              full_name: {type: :string, example: "Jane Doe"}
            },
            required: %w[id serial_number email full_name]
          },
          Book: {
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              serial_number: {type: :string, example: "100001"},
              title: {type: :string, example: "The Great Gatsby"},
              author: {type: :string, example: "F. Scott Fitzgerald"}
            },
            required: %w[id serial_number title author]
          },
          BookWithStatus: {
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              serial_number: {type: :string, example: "100001"},
              title: {type: :string, example: "The Great Gatsby"},
              author: {type: :string, example: "F. Scott Fitzgerald"},
              status: {type: :string, enum: %w[borrowed available], example: "available"}
            },
            required: %w[id serial_number title author status]
          },
          BookBorrow: {
            type: :object,
            properties: {
              reader_card_number: {type: :string, example: "100001"},
              reader_email: {type: :string, format: :email, example: "reader@example.com"},
              borrow_date: {type: :string, format: :date, example: "2026-02-16"},
              due_date: {type: :string, format: :date, example: "2026-03-18"},
              return_date: {type: :string, format: :date, nullable: true, example: nil}
            },
            required: %w[reader_card_number reader_email borrow_date due_date]
          },
          BookWithBorrows: {
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              serial_number: {type: :string, example: "100001"},
              title: {type: :string, example: "The Great Gatsby"},
              author: {type: :string, example: "F. Scott Fitzgerald"},
              status: {type: :string, enum: %w[borrowed available], example: "available"},
              borrows: {type: :array, items: {"$ref" => "#/components/schemas/BookBorrow"}}
            },
            required: %w[id serial_number title author status borrows]
          }
        }
      }
    }
  }

  config.openapi_format = :json
  config.openapi_strict_schema_validation = true
end
