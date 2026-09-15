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
    end

    def post_request(path, body:, headers: {})
      handle_response(client.connection.post(path, body, headers))
    end

    def handle_response(response)
      parse_body(response.body)
    end

    def parse_body(body)
      return body unless body.is_a?(String)

      JSON.parse(body)
    rescue JSON::ParserError
      body
    end
  end
end
