module V1
  class HealthController < ApplicationController
    BOOT_TIME = Time.now.freeze

    def live
      render json: {status: "ok"}
    end

    def ready
      checks = {
        database: database_check
      }

      status = checks.values.all?("ok") ? "ok" : "error"
      http_status = (status == "ok") ? :ok : :service_unavailable

      render json: {
        status: status,
        uptime: uptime_seconds,
        checks: checks
      }, status: http_status
    end

    private

    def database_check
      ActiveRecord::Base.connection.execute("SELECT 1")
      "ok"
    rescue => _e
      "error"
    end

    def uptime_seconds
      (Time.now - BOOT_TIME).round(1)
    end
  end
end
