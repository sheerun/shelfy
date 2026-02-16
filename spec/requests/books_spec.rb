require "swagger_helper"

RSpec.describe "Books", type: :request do
  path "/books" do
    get "List books" do
      tags "Books"
      description "Returns a paginated list of all books with their borrow status"
      produces "application/json"

      parameter name: :page, in: :query, type: :integer, required: false,
        description: "Page number (default: 1)"
      parameter name: :per_page, in: :query, type: :integer, required: false,
        description: "Items per page (default: 20, max: 50)"
      parameter name: :status, in: :query, type: :string, required: false,
        enum: %w[borrowed available],
        description: "Filter by borrow status"

      response "200", "Books listed successfully" do
        schema type: :object,
          properties: {
            data: {type: :array, items: {"$ref" => "#/components/schemas/BookWithStatus"}},
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
          data["data"].each do |book|
            expect(book["status"]).to eq("available")
          end
        end
      end

      response "200", "Books filtered by status" do
        schema type: :object,
          properties: {
            data: {type: :array, items: {"$ref" => "#/components/schemas/BookWithStatus"}},
            meta: {type: :object}
          },
          required: %w[data meta]

        let(:status) { "borrowed" }

        before do
          reader = create(:reader)
          borrowed = create(:book)
          create(:book_borrow, book: borrowed, reader: reader)
          create(:book) # available book
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"].length).to eq(1)
          expect(data["data"][0]["status"]).to eq("borrowed")
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
      description "Returns a single book by ID, including borrow history"
      produces "application/json"

      parameter name: :id, in: :path, type: :string, format: :uuid,
        description: "Book ID"

      response "200", "Book found" do
        schema type: :object,
          properties: {
            data: {"$ref" => "#/components/schemas/BookWithBorrows"}
          },
          required: %w[data]

        let(:existing_book) { create(:book) }
        let(:id) { existing_book.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["id"]).to eq(existing_book.id)
          expect(data["data"]["serial_number"]).to eq(existing_book.serial_number)
          expect(data["data"]["status"]).to eq("available")
          expect(data["data"]["borrows"]).to eq([])
        end
      end

      response "200", "Book with borrow history" do
        schema type: :object,
          properties: {
            data: {"$ref" => "#/components/schemas/BookWithBorrows"}
          },
          required: %w[data]

        let(:existing_book) { create(:book) }
        let(:reader) { create(:reader) }
        let(:id) { existing_book.id }

        before do
          create(:book_borrow, book: existing_book, reader: reader)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["status"]).to eq("borrowed")
          expect(data["data"]["borrows"].length).to eq(1)
          borrow = data["data"]["borrows"][0]
          expect(borrow["reader_card_number"]).to eq(reader.serial_number)
          expect(borrow["reader_email"]).to eq(reader.email)
          expect(borrow["borrow_date"]).to be_present
          expect(borrow["due_date"]).to be_present
          expect(borrow["return_date"]).to be_nil
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

  path "/books/{id}/borrow" do
    post "Borrow a book" do
      tags "Books"
      description "Borrows a book for a reader. Books are borrowed for 30 days."
      consumes "application/json"
      produces "application/json"

      parameter name: :id, in: :path, type: :string, format: :uuid,
        description: "Book ID"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          reader_id: {type: :string, format: :uuid, description: "Reader ID"}
        },
        required: %w[reader_id]
      }

      response "201", "Book borrowed successfully" do
        schema type: :object,
          properties: {
            data: {"$ref" => "#/components/schemas/BookBorrow"}
          },
          required: %w[data]

        let(:existing_book) { create(:book) }
        let(:reader) { create(:reader) }
        let(:id) { existing_book.id }
        let(:body) { {reader_id: reader.id} }

        request_body_example value: {reader_id: "550e8400-e29b-41d4-a716-446655440000"},
          name: "borrow_book",
          summary: "Borrow a book"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["reader_card_number"]).to eq(reader.serial_number)
          expect(data["data"]["reader_email"]).to eq(reader.email)
          expect(data["data"]["borrow_date"]).to eq(Date.current.to_s)
          expect(data["data"]["due_date"]).to eq((Date.current + 30.days).to_s)
          expect(data["data"]["return_date"]).to be_nil
        end
      end

      response "422", "Book already borrowed" do
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

        let(:existing_book) { create(:book) }
        let(:reader) { create(:reader) }
        let(:another_reader) { create(:reader) }
        let(:id) { existing_book.id }
        let(:body) { {reader_id: another_reader.id} }

        before { create(:book_borrow, book: existing_book, reader: reader) }

        request_body_example value: {reader_id: "550e8400-e29b-41d4-a716-446655440000"},
          name: "already_borrowed",
          summary: "Book already borrowed"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["message"]).to eq("Book is already borrowed")
        end
      end

      response "404", "Book not found" do
        let(:id) { "00000000-0000-0000-0000-000000000000" }
        let(:reader) { create(:reader) }
        let(:body) { {reader_id: reader.id} }

        run_test!
      end
    end
  end

  path "/books/{id}/return" do
    post "Return a book" do
      tags "Books"
      description "Returns a borrowed book"
      produces "application/json"

      parameter name: :id, in: :path, type: :string, format: :uuid,
        description: "Book ID"

      response "200", "Book returned successfully" do
        schema type: :object,
          properties: {
            data: {"$ref" => "#/components/schemas/BookBorrow"}
          },
          required: %w[data]

        let(:existing_book) { create(:book) }
        let(:reader) { create(:reader) }
        let(:id) { existing_book.id }

        before { create(:book_borrow, book: existing_book, reader: reader) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["return_date"]).to eq(Date.current.to_s)
          expect(data["data"]["reader_card_number"]).to eq(reader.serial_number)
        end
      end

      response "422", "Book not currently borrowed" do
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

        let(:existing_book) { create(:book) }
        let(:id) { existing_book.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["message"]).to eq("Book is not currently borrowed")
        end
      end

      response "404", "Book not found" do
        let(:id) { "00000000-0000-0000-0000-000000000000" }

        run_test!
      end
    end
  end

  describe "End-to-end borrow and return flow", type: :request do
    let(:book) { create(:book) }
    let(:reader1) { create(:reader) }
    let(:reader2) { create(:reader) }

    it "supports full borrow-return lifecycle" do
      # Book starts as available
      get "/books/#{book.id}"
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["data"]["status"]).to eq("available")
      expect(data["data"]["borrows"]).to eq([])

      # Borrow the book
      post "/books/#{book.id}/borrow", params: {reader_id: reader1.id}, as: :json
      expect(response).to have_http_status(:created)
      borrow_data = JSON.parse(response.body)
      expect(borrow_data["data"]["reader_card_number"]).to eq(reader1.serial_number)

      # Book is now borrowed
      get "/books/#{book.id}"
      data = JSON.parse(response.body)
      expect(data["data"]["status"]).to eq("borrowed")
      expect(data["data"]["borrows"].length).to eq(1)

      # Cannot borrow again while borrowed
      post "/books/#{book.id}/borrow", params: {reader_id: reader2.id}, as: :json
      expect(response).to have_http_status(:unprocessable_entity)

      # Return the book
      post "/books/#{book.id}/return"
      expect(response).to have_http_status(:ok)
      return_data = JSON.parse(response.body)
      expect(return_data["data"]["return_date"]).to eq(Date.current.to_s)

      # Book is available again
      get "/books/#{book.id}"
      data = JSON.parse(response.body)
      expect(data["data"]["status"]).to eq("available")
      expect(data["data"]["borrows"].length).to eq(1)
      expect(data["data"]["borrows"][0]["return_date"]).to be_present

      # Cannot return a book that is not borrowed
      post "/books/#{book.id}/return"
      expect(response).to have_http_status(:unprocessable_entity)

      # Borrow again by another reader
      post "/books/#{book.id}/borrow", params: {reader_id: reader2.id}, as: :json
      expect(response).to have_http_status(:created)

      # Book now has two borrow records
      get "/books/#{book.id}"
      data = JSON.parse(response.body)
      expect(data["data"]["status"]).to eq("borrowed")
      expect(data["data"]["borrows"].length).to eq(2)
      expect(data["data"]["borrows"][0]["reader_card_number"]).to eq(reader2.serial_number)
      expect(data["data"]["borrows"][1]["reader_card_number"]).to eq(reader1.serial_number)

      # List books shows correct statuses
      get "/books", params: {status: "borrowed"}
      data = JSON.parse(response.body)
      expect(data["data"].length).to eq(1)

      get "/books", params: {status: "available"}
      data = JSON.parse(response.body)
      expect(data["data"].length).to eq(0)
    end
  end
end
