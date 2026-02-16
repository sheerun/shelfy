class ApplicationController < ActionController::API
  private

  def execute(query_or_command_class, params = {})
    result = query_or_command_class.new(params).execute
    render_result(result)
  end

  def render_result(result)
    return head :not_found if result.status == :not_found && result.errors.present?

    if result.success?
      status = result.status || :ok
      if result.data.is_a?(Hash) && result.data.key?(:data) && result.data.key?(:meta)
        render json: result.data, status: status
      elsif result.data
        render json: {data: result.data}, status: status
      else
        head status
      end
    else
      http_status = case result.status
      when :not_found then :not_found
      when :unprocessable then :unprocessable_entity
      else :bad_request
      end

      body = {error: {message: error_message_from(result.errors)}}
      body[:errors] = result.errors if result.errors.is_a?(Hash)

      render json: body, status: http_status
    end
  end

  def error_message_from(errors)
    return errors if errors.is_a?(String)
    return errors[:base] if errors.is_a?(Hash) && errors[:base]
    "Validation failed"
  end
end
