# frozen_string_literal: true

require_relative "hive_api/version"

module HiveAPI
  autoload :Client, "hive_api/client"
  autoload :Base, "hive_api/object"
  autoload :Resource, "hive_api/resource"
  autoload :Error, "hive_api/errors"
  autoload :APIError, "hive_api/errors"
  autoload :AuthenticationError, "hive_api/errors"
  autoload :ValidationError, "hive_api/errors"
  autoload :NotFoundError, "hive_api/errors"
  autoload :RateLimitError, "hive_api/errors"
  autoload :ServerError, "hive_api/errors"
  autoload :ReturnRulesResource, "hive_api/resources/return_rules_resource"
  autoload :ReturnsResource, "hive_api/resources/returns_resource"

  module Objects
    autoload :PaginationResponse, "hive_api/objects/pagination_response"
    autoload :ReturnListResponse, "hive_api/objects/return_list_response"
    autoload :ReturnResponse, "hive_api/objects/return_response"
    autoload :ReturnRulesResponse, "hive_api/objects/return_rules_response"
  end
end
