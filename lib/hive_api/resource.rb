# frozen_string_literal: true

require "json"

module HiveAPI
  class Resource
    attr_reader :client

    def initialize(client)
      @client = client
    end

    private

    def get_request(path, params: {}, headers: {})
      handle_response(client.connection.get(path, params, headers))
    rescue Faraday::Error => error
      raise_transport_error(error)
    end

    def post_request(path, body:, headers: {})
      handle_response(client.connection.post(path, body, headers))
    rescue Faraday::Error => error
      raise_transport_error(error)
    end

    def handle_response(response)
      body = parse_body(response.body)
      return body if response.status.between?(200, 299)

      error_class, prefix = error_mapping(response.status)
      message = "#{prefix} (HTTP #{response.status}): #{extract_error_message(body)}"
      raise error_class.new(
        message,
        response: response,
        status_code: response.status,
        rate_limit_used: numeric_header(response, "x-rate-limit-used"),
        rate_limit_max: numeric_header(response, "x-rate-limit-max"),
        retry_after: numeric_header(response, "retry-after")
      )
    end

    def parse_body(body)
      return body unless body.is_a?(String)

      JSON.parse(body)
    rescue JSON::ParserError
      body
    end

    def extract_error_message(body)
      message = case body
      when Hash
        approved_error_message(body)
      when String
        body
      end

      redact_credentials(message || "Unknown error")
    end

    def approved_error_message(body)
      [body["message"], body[:message], body["error"], body[:error]]
        .find { |value| value.is_a?(String) } || errors_message(body)
    end

    def errors_message(body)
      errors = body["errors"] || body[:errors]
      return errors if errors.is_a?(String)
      return unless errors.is_a?(Array)

      messages = errors.select { |error| error.is_a?(String) }
      messages.join(", ") unless messages.empty?
    end

    def redact_credentials(message)
      redacted = message.dup
      redacted.gsub!(/\bAuthorization\s*:\s*[^,;]+/i, "[REDACTED]")
      redacted.gsub!(/\bBearer\s+[^\s,;]+/i, "[REDACTED]")
      redacted.gsub!(client.api_token, "[REDACTED]")
      redacted
    end

    def error_mapping(status)
      case status
      when 400 then [ValidationError, "Bad request"]
      when 401, 403 then [AuthenticationError, "Authentication failed"]
      when 404 then [NotFoundError, "Resource not found"]
      when 429 then [RateLimitError, "Rate limited"]
      when 500..599 then [ServerError, "Server error"]
      else [APIError, "API error"]
      end
    end

    def numeric_header(response, name)
      value = response.headers[name]
      return if value.nil?

      Integer(value, exception: false) || Float(value, exception: false)
    end

    def raise_transport_error(error)
      wrapped_error = APIError.new(
        "Network request failed",
        response: error.response,
        status_code: error.response_status
      )
      raise wrapped_error, cause: error
    end
  end
end
