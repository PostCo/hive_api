# frozen_string_literal: true

module HiveAPI
  class Error < StandardError
    attr_reader :response, :status_code, :rate_limit_used, :rate_limit_max, :retry_after

    def initialize(message = nil, response: nil, status_code: nil, rate_limit_used: nil,
      rate_limit_max: nil, retry_after: nil)
      super(message)
      @response = response
      @status_code = status_code
      @rate_limit_used = rate_limit_used
      @rate_limit_max = rate_limit_max
      @retry_after = retry_after
    end
  end

  class APIError < Error; end

  class AuthenticationError < Error; end

  class ValidationError < Error; end

  class NotFoundError < Error; end

  class RateLimitError < Error; end

  class ServerError < Error; end
end
