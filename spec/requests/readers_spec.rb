require "swagger_helper"

RSpec.describe "Readers", type: :request do
  let(:reader_schema) do
    {
      type: :object,
      properties: {
        id: {type: :string, format: :uuid},
        serial_number: {type: :string, example: "100001"},
        email: {type: :string, format: :email, example: "reader@example.com"},
        full_name: {type: :string, example: "Jane Doe"}
      },
      required: %w[id serial_number email full_name]
    }
  end

  let(:error_schema) do
    {
      type: :object,
      properties: {
        error: {
          type: :object,
          properties: {
            message: {type: :string}
          },
          required: %w[message]
        },
        errors: {type: :object}
      },
      required: %w[error]
    }
  end

  path "/readers" do
    get "List readers" do
      tags "Readers"
      description "Returns a paginated list of all readers"
      produces "application/json"

      parameter name: :page, in: :query, type: :integer, required: false,
        description: "Page number (default: 1)"
      parameter name: :per_page, in: :query, type: :integer, required: false,
        description: "Items per page (default: 20, max: 50)"

      response "200", "Readers listed successfully" do
        schema type: :object,
          properties: {
            data: {type: :array, items: {"$ref" => "#/components/schemas/Reader"}},
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

        before { create_list(:reader, 3) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"].length).to eq(3)
          expect(data["meta"]["total"]).to eq(3)
          expect(data["meta"]["page"]).to eq(1)
        end
      end
    end

    post "Register a new reader" do
      tags "Readers"
      description "Creates a new reader with the given attributes"
      consumes "application/json"
      produces "application/json"

      parameter name: :reader, in: :body, schema: {
        type: :object,
        properties: {
          reader: {
            type: :object,
            properties: {
              serial_number: {type: :string, example: "100001"},
              email: {type: :string, format: :email, example: "reader@example.com"},
              full_name: {type: :string, example: "Jane Doe"}
            },
            required: %w[serial_number email full_name]
          }
        },
        required: %w[reader]
      }

      response "201", "Reader registered successfully" do
        schema type: :object,
          properties: {
            data: {"$ref" => "#/components/schemas/Reader"}
          },
          required: %w[data]

        let(:reader) { {reader: {serial_number: "100001", email: "test@example.com", full_name: "Jane Doe"}} }

        request_body_example value: {reader: {serial_number: "100001", email: "test@example.com", full_name: "Jane Doe"}},
          name: "valid_reader",
          summary: "Valid reader registration"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["serial_number"]).to eq("100001")
          expect(data["data"]["email"]).to eq("test@example.com")
          expect(data["data"]["full_name"]).to eq("Jane Doe")
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

        let(:reader) { {reader: {serial_number: "", email: "", full_name: ""}} }

        request_body_example value: {reader: {serial_number: "", email: "", full_name: ""}},
          name: "invalid_reader",
          summary: "Invalid reader - missing fields"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["message"]).to eq("Validation failed")
          expect(data["errors"]).to be_present
        end
      end

      response "422", "Duplicate email" do
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

        before { create(:reader, email: "taken@example.com") }
        let(:reader) { {reader: {serial_number: "200001", email: "taken@example.com", full_name: "Another Reader"}} }

        request_body_example value: {reader: {serial_number: "200001", email: "taken@example.com", full_name: "Another Reader"}},
          name: "duplicate_email",
          summary: "Duplicate email address"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["errors"]).to be_present
        end
      end
    end
  end

  path "/readers/{id}" do
    get "Get a reader" do
      tags "Readers"
      description "Returns a single reader by ID"
      produces "application/json"

      parameter name: :id, in: :path, type: :string, format: :uuid,
        description: "Reader ID"

      response "200", "Reader found" do
        schema type: :object,
          properties: {
            data: {"$ref" => "#/components/schemas/Reader"}
          },
          required: %w[data]

        let(:existing_reader) { create(:reader) }
        let(:id) { existing_reader.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["id"]).to eq(existing_reader.id)
          expect(data["data"]["serial_number"]).to eq(existing_reader.serial_number)
        end
      end

      response "404", "Reader not found" do
        let(:id) { "00000000-0000-0000-0000-000000000000" }

        run_test!
      end
    end

    patch "Update a reader" do
      tags "Readers"
      description "Updates an existing reader's attributes"
      consumes "application/json"
      produces "application/json"

      parameter name: :id, in: :path, type: :string, format: :uuid,
        description: "Reader ID"
      parameter name: :reader, in: :body, schema: {
        type: :object,
        properties: {
          reader: {
            type: :object,
            properties: {
              serial_number: {type: :string, example: "200002"},
              email: {type: :string, format: :email, example: "updated@example.com"},
              full_name: {type: :string, example: "Updated Name"}
            }
          }
        },
        required: %w[reader]
      }

      response "200", "Reader updated successfully" do
        schema type: :object,
          properties: {
            data: {"$ref" => "#/components/schemas/Reader"}
          },
          required: %w[data]

        let(:existing_reader) { create(:reader) }
        let(:id) { existing_reader.id }
        let(:reader) { {reader: {full_name: "Updated Name"}} }

        request_body_example value: {reader: {full_name: "Updated Name"}},
          name: "update_name",
          summary: "Update reader name"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["full_name"]).to eq("Updated Name")
          expect(data["data"]["id"]).to eq(existing_reader.id)
        end
      end

      response "404", "Reader not found" do
        let(:id) { "00000000-0000-0000-0000-000000000000" }
        let(:reader) { {reader: {full_name: "Updated Name"}} }

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

        let(:other_reader) { create(:reader, email: "taken@example.com") }
        let(:existing_reader) { create(:reader) }
        let(:id) { existing_reader.id }
        let(:reader) { {reader: {email: other_reader.email}} }

        request_body_example value: {reader: {email: "taken@example.com"}},
          name: "duplicate_email_update",
          summary: "Update with duplicate email"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["errors"]).to be_present
        end
      end
    end

    delete "Delete a reader" do
      tags "Readers"
      description "Removes a reader from the system"
      produces "application/json"

      parameter name: :id, in: :path, type: :string, format: :uuid,
        description: "Reader ID"

      response "200", "Reader deleted successfully" do
        let(:existing_reader) { create(:reader) }
        let(:id) { existing_reader.id }

        run_test! do
          expect(Reader.find_by(id: existing_reader.id)).to be_nil
        end
      end

      response "404", "Reader not found" do
        let(:id) { "00000000-0000-0000-0000-000000000000" }

        run_test!
      end
    end
  end
end
