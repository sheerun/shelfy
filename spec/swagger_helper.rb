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
        schemas: {}
      }
    }
  }

  config.openapi_format = :json
  config.openapi_strict_schema_validation = true
end
