# frozen_string_literal: true

require "faraday"

module HiveAPI
  class Client
    PRODUCTION_BASE_URL = "https://app.hive.app/merchant_api/v2/"
    STAGING_BASE_URL = "https://staging.app.hive.app/merchant_api/v2/"
    MOCK_BASE_URL = "https://hive-merchant-api.redocly.app/_mock/merchant-api-v2/mapi_v2_oas31/"
    BASE_URLS = {
      production: PRODUCTION_BASE_URL,
      staging: STAGING_BASE_URL,
      mock: MOCK_BASE_URL
    }.freeze
    DEFAULT_ENVIRONMENT = :production
    DEFAULT_OPEN_TIMEOUT = 5
    DEFAULT_TIMEOUT = 15

    attr_reader :adapter, :base_url, :environment, :open_timeout, :timeout

    def initialize(environment: DEFAULT_ENVIRONMENT, adapter: Faraday.default_adapter,
      open_timeout: DEFAULT_OPEN_TIMEOUT, timeout: DEFAULT_TIMEOUT)
      @environment = normalize_environment(environment)
      @base_url = BASE_URLS.fetch(@environment)
      @adapter = adapter
      @open_timeout = open_timeout
      @timeout = timeout
    end

    def connection
      @connection ||= Faraday.new do |connection|
        connection.url_prefix = base_url
        connection.options.open_timeout = open_timeout
        connection.options.timeout = timeout
        connection.headers["Accept"] = "application/json"
        connection.request :json
        connection.response :json, content_type: /\bjson/
        connection.adapter adapter
      end
    end

    private

    def normalize_environment(environment)
      normalized = environment.respond_to?(:to_sym) ? environment.to_sym : environment
      return normalized if BASE_URLS.key?(normalized)

      raise ArgumentError,
        "environment must be one of: #{BASE_URLS.keys.join(", ")}"
    end
  end
end
