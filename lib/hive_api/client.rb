# frozen_string_literal: true

require "faraday"

module HiveAPI
  class Client
    LIVE_BASE_URL = "https://app.hive.app/merchant_api/v2/"
    TEST_BASE_URL = "https://staging.app.hive.app/merchant_api/v2/"
    DEFAULT_OPEN_TIMEOUT = 5
    DEFAULT_TIMEOUT = 15

    attr_reader :adapter, :api_token, :open_timeout, :timeout

    def initialize(api_token:, sandbox: true, adapter: Faraday.default_adapter,
      open_timeout: DEFAULT_OPEN_TIMEOUT, timeout: DEFAULT_TIMEOUT)
      validate_api_token!(api_token)

      @api_token = api_token
      @sandbox = sandbox
      @adapter = adapter
      @open_timeout = open_timeout
      @timeout = timeout
    end

    def connection
      @connection ||= Faraday.new do |connection|
        connection.url_prefix = sandbox? ? TEST_BASE_URL : LIVE_BASE_URL
        connection.options.open_timeout = open_timeout
        connection.options.timeout = timeout
        connection.headers["Authorization"] = "Bearer #{api_token}"
        connection.headers["Accept"] = "application/json"
        connection.request :json
        connection.response :json, content_type: /\bjson/
        connection.adapter adapter
      end
    end

    private

    def validate_api_token!(api_token)
      return if api_token.is_a?(String) && !api_token.strip.empty?

      raise ArgumentError, "api_token must be a non-empty String"
    end

    def sandbox?
      @sandbox
    end
  end
end
