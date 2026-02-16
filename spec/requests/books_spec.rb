require "swagger_helper"

RSpec.describe "Books", type: :request do
  path "/books" do
    get "List books" do
      tags "Books"
      description "Returns a paginated list of all books"
      produces "application/json"

      parameter name: :page, in: :query, type: :integer, required: false,
        description: "Page number (default: 1)"
      parameter name: :per_page, in: :query, type: :integer, required: false,
        description: "Items per page (default: 20, max: 50)"

      response "200", "Books listed successfully" do
        schema type: :object,
          properties: {
            data: {type: :array, items: {"$ref" => "#/components/schemas/Book"}},
            meta: {
              type: :object,
              properties: {
                total: {type: :integer},
                page: {type: :integer},
                per_page: {type: :integer}
              },
              required: %w[total page per_page]
            }
          },
          required: %w[data meta]

        before { create_list(:book, 3) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"].length).to eq(3)
          expect(data["meta"]["total"]).to eq(3)
          expect(data["meta"]["page"]).to eq(1)
        end
      end
    end

    post "Register a new book" do
      tags "Books"
      description "Creates a new book with the given attributes"
      consumes "application/json"
      produces "application/json"

      parameter name: :book, in: :body, schema: {
        type: :object,
        properties: {
          book: {
            type: :object,
            properties: {
              serial_number: {type: :string, example: "100001"},
              title: {type: :string, example: "The Great Gatsby"},
              author: {type: :string, example: "F. Scott Fitzgerald"}
            },
            required: %w[serial_number title author]
          }
        },
        required: %w[book]
      }

      response "201", "Book registered successfully" do
        schema type: :object,
          properties: {
            data: {"$ref" => "#/components/schemas/Book"}
          },
          required: %w[data]

        let(:book) { {book: {serial_number: "100001", title: "The Great Gatsby", author: "F. Scott Fitzgerald"}} }

        request_body_example value: {book: {serial_number: "100001", title: "The Great Gatsby", author: "F. Scott Fitzgerald"}},
          name: "valid_book",
          summary: "Valid book registration"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["serial_number"]).to eq("100001")
          expect(data["data"]["title"]).to eq("The Great Gatsby")
          expect(data["data"]["author"]).to eq("F. Scott Fitzgerald")
          expect(data["data"]["id"]).to be_present
        end
      end

      response "422", "Validation failed" do
        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {message: {type: :string}},
              required: %w[message]
            },
            errors: {type: :object}
          },
          required: %w[error]

        let(:book) { {book: {serial_number: "", title: "", author: ""}} }

        request_body_example value: {book: {serial_number: "", title: "", author: ""}},
          name: "invalid_book",
          summary: "Invalid book - missing fields"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["message"]).to eq("Validation failed")
          expect(data["errors"]).to be_present
        end
      end

      response "422", "Duplicate serial number" do
        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {message: {type: :string}},
              required: %w[message]
            },
            errors: {type: :object}
          },
          required: %w[error]

        before { create(:book, serial_number: "100001") }
        let(:book) { {book: {serial_number: "100001", title: "Another Book", author: "Another Author"}} }

        request_body_example value: {book: {serial_number: "100001", title: "Another Book", author: "Another Author"}},
          name: "duplicate_serial_number",
          summary: "Duplicate serial number"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["errors"]).to be_present
        end
      end
    end
  end

  path "/books/{id}" do
    get "Get a book" do
      tags "Books"
      description "Returns a single book by ID"
      produces "application/json"

      parameter name: :id, in: :path, type: :string, format: :uuid,
        description: "Book ID"

      response "200", "Book found" do
        schema type: :object,
          properties: {
            data: {"$ref" => "#/components/schemas/Book"}
          },
          required: %w[data]

        let(:existing_book) { create(:book) }
        let(:id) { existing_book.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["id"]).to eq(existing_book.id)
          expect(data["data"]["serial_number"]).to eq(existing_book.serial_number)
        end
      end

      response "404", "Book not found" do
        let(:id) { "00000000-0000-0000-0000-000000000000" }

        run_test!
      end
    end

    patch "Update a book" do
      tags "Books"
      description "Updates an existing book's attributes"
      consumes "application/json"
      produces "application/json"

      parameter name: :id, in: :path, type: :string, format: :uuid,
        description: "Book ID"
      parameter name: :book, in: :body, schema: {
        type: :object,
        properties: {
          book: {
            type: :object,
            properties: {
              serial_number: {type: :string, example: "200002"},
              title: {type: :string, example: "Updated Title"},
              author: {type: :string, example: "Updated Author"}
            }
          }
        },
        required: %w[book]
      }

      response "200", "Book updated successfully" do
        schema type: :object,
          properties: {
            data: {"$ref" => "#/components/schemas/Book"}
          },
          required: %w[data]

        let(:existing_book) { create(:book) }
        let(:id) { existing_book.id }
        let(:book) { {book: {title: "Updated Title"}} }

        request_body_example value: {book: {title: "Updated Title"}},
          name: "update_title",
          summary: "Update book title"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["title"]).to eq("Updated Title")
          expect(data["data"]["id"]).to eq(existing_book.id)
        end
      end

      response "404", "Book not found" do
        let(:id) { "00000000-0000-0000-0000-000000000000" }
        let(:book) { {book: {title: "Updated Title"}} }

        run_test!
      end

      response "422", "Validation failed" do
        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {message: {type: :string}},
              required: %w[message]
            },
            errors: {type: :object}
          },
          required: %w[error]

        let(:other_book) { create(:book, serial_number: "200001") }
        let(:existing_book) { create(:book) }
        let(:id) { existing_book.id }
        let(:book) { {book: {serial_number: other_book.serial_number}} }

        request_body_example value: {book: {serial_number: "200001"}},
          name: "duplicate_serial_number_update",
          summary: "Update with duplicate serial number"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["errors"]).to be_present
        end
      end
    end

    delete "Delete a book" do
      tags "Books"
      description "Removes a book from the system"
      produces "application/json"

      parameter name: :id, in: :path, type: :string, format: :uuid,
        description: "Book ID"

      response "200", "Book deleted successfully" do
        let(:existing_book) { create(:book) }
        let(:id) { existing_book.id }

        run_test! do
          expect(Book.find_by(id: existing_book.id)).to be_nil
        end
      end

      response "404", "Book not found" do
        let(:id) { "00000000-0000-0000-0000-000000000000" }

        run_test!
      end
    end
  end
end
