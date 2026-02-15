require "swagger_helper"

RSpec.describe "Health", type: :request do
  path "/v1/health/live" do
    get "Liveness probe" do
      tags "Health"
      description "Returns 200 if the application is running. Used for Kubernetes liveness probes."
      produces "application/json"

      response "200", "Application is live" do
        schema type: :object,
          properties: {
            status: {type: :string, example: "ok"}
          },
          required: ["status"]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
        end
      end
    end
  end

  path "/v1/health/ready" do
    get "Readiness probe" do
      tags "Health"
      description "Returns 200 if the application is ready to serve requests. " \
                  "Checks database connectivity. Used for Kubernetes readiness probes."
      produces "application/json"

      response "200", "Application is ready" do
        schema type: :object,
          properties: {
            status: {type: :string, example: "ok"},
            uptime: {type: :number, description: "Uptime in seconds"},
            checks: {
              type: :object,
              properties: {
                database: {type: :string, example: "ok"}
              },
              required: ["database"]
            }
          },
          required: ["status", "uptime", "checks"]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["uptime"]).to be_a(Numeric)
          expect(data["checks"]["database"]).to eq("ok")
        end
      end

      response "503", "Application is not ready" do
        schema type: :object,
          properties: {
            status: {type: :string, example: "error"},
            uptime: {type: :number, description: "Uptime in seconds"},
            checks: {
              type: :object,
              properties: {
                database: {type: :string, example: "error"}
              },
              required: ["database"]
            }
          },
          required: ["status", "uptime", "checks"]

        before do
          allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(ActiveRecord::ConnectionNotEstablished)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["checks"]["database"]).to eq("error")
        end
      end
    end
  end
end
