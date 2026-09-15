# frozen_string_literal: true

require_relative "hive_api/version"

module HiveAPI
  autoload :Client, "hive_api/client"
  autoload :Base, "hive_api/object"
  autoload :Resource, "hive_api/resource"
  autoload :Error, "hive_api/errors"
  autoload :APIError, "hive_api/errors"

  module Objects
  end
end
