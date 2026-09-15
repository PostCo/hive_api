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

  module Objects
  end
end
