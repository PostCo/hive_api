# frozen_string_literal: true

module HiveAPI
  module Objects
    class ReturnListResponse < Base
      private

      def nested_object_class(key)
        case key.to_s
        when "data" then ReturnResponse
        when "pagination" then PaginationResponse
        end
      end
    end
  end
end
