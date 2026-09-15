# frozen_string_literal: true

module HiveAPI
  class ReturnRulesResource < Resource
    def get
      Objects::ReturnRulesResponse.new(get_request("return_rules"))
    end
  end
end
