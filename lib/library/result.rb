module Library
  class Result
    attr_reader :data, :errors, :status

    def initialize(data: nil, errors: nil, status: :ok)
      @data = data
      @errors = errors
      @status = status
    end

    def success?
      errors.nil?
    end

    def failure?
      !success?
    end
  end
end
