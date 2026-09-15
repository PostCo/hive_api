# frozen_string_literal: true

require "uri"

module HiveAPI
  class ReturnsResource < Resource
    INVALID_PAGE_URL_MESSAGE = "url must be a Returns page URL for the selected Hive environment"

    def list(
      sales_channel_id_in: nil,
      created_at_gt: nil,
      created_at_lt: nil,
      created_at_gte: nil,
      created_at_lte: nil,
      limit: nil
    )
      params = {
        "sales_channel_id[in]" => serialize_sales_channel_ids(sales_channel_id_in),
        "created_at[gt]" => created_at_gt,
        "created_at[lt]" => created_at_lt,
        "created_at[gte]" => created_at_gte,
        "created_at[lte]" => created_at_lte,
        "limit" => limit
      }.compact

      build_list_response(get_request("returns", params: params))
    end

    def list_page(url:)
      validate_page_url!(url)
      build_list_response(get_request(url))
    end

    def find(id:)
      Objects::ReturnResponse.new(get_request("returns/#{id}"))
    end

    private

    def build_list_response(data)
      Objects::ReturnListResponse.new(data)
    end

    def serialize_sales_channel_ids(value)
      value.is_a?(Array) ? value.join(",") : value
    end

    def validate_page_url!(url)
      page_uri = URI.parse(url)
      base_uri = URI.parse(client.connection.url_prefix.to_s)
      returns_path = URI.join(base_uri.to_s, "returns").path

      valid = url.is_a?(String) &&
        page_uri.absolute? &&
        page_uri.userinfo.nil? &&
        page_uri.fragment.nil? &&
        page_uri.scheme == base_uri.scheme &&
        page_uri.host == base_uri.host &&
        page_uri.port == base_uri.port &&
        page_uri.path == returns_path

      raise ArgumentError, INVALID_PAGE_URL_MESSAGE unless valid
    rescue URI::Error, TypeError
      raise ArgumentError, INVALID_PAGE_URL_MESSAGE
    end
  end
end
