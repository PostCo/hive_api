# frozen_string_literal: true

require_relative "../lib/hive_api"

module HiveAPI
  class ContractSmoke
    def initialize(client:, output: $stdout)
      @client = client
      @output = output
    end

    def run
      client.return_rules.get
      output.puts "PASS GET /return_rules"

      page = client.returns.list(limit: 1)
      output.puts "PASS GET /returns"

      if page.data.empty?
        output.puts "SKIP GET /returns/{id}: staging returned no data; record this limitation for Tapir staging"
        return
      end

      client.returns.find(id: page.data.first.id)
      output.puts "PASS GET /returns/{id}"
    end

    private

    attr_reader :client, :output
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    token = ENV.fetch("HIVE_API_TOKEN", "")
    abort "HIVE_API_TOKEN must contain a staging token" if token.strip.empty?

    client = HiveAPI::Client.new(api_token: token, sandbox: true)
    HiveAPI::ContractSmoke.new(client: client).run
  rescue HiveAPI::Error => error
    status = error.status_code || "unavailable"
    abort "FAIL #{error.class} (HTTP status: #{status})"
  rescue => error
    abort "FAIL #{error.class}"
  end
end
