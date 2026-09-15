# frozen_string_literal: true

require "json"

RSpec.describe HiveAPI::ReturnRulesResource do
  subject(:return_rules) { client.return_rules }

  let(:api_token) { "return-rules-api-token" }
  let(:client) { HiveAPI::Client.new(api_token: api_token) }
  let(:endpoint) { "#{HiveAPI::Client::TEST_BASE_URL}return_rules" }

  describe "#get" do
    it "gets the return rules with Bearer authentication and maps the complete response" do
      response = {
        "send_back_address" => {
          "first_name" => "Returns",
          "last_name" => "Team",
          "company" => "Merchant GmbH",
          "line1" => "Hive Street 1",
          "line2" => "Unit 2",
          "city" => "Berlin",
          "postal_code" => "10115",
          "province_or_state_code" => "BE",
          "country_code" => "DE"
        },
        "default_rules" => {"A" => "restock", "B" => "send_back", "C" => "dispose"},
        "sku_rules" => [
          {
            "sku" => {"id" => 1001, "sku_code" => "SKU-001"},
            "A" => "send_back",
            "B" => nil,
            "C" => "dispose"
          }
        ]
      }
      request = stub_request(:get, endpoint)
        .with(headers: {
          "Accept" => "application/json",
          "Authorization" => "Bearer #{api_token}"
        })
        .to_return(
          status: 200,
          body: JSON.generate(response),
          headers: {"Content-Type" => "application/json"}
        )

      result = return_rules.get

      expect(request).to have_been_requested.once
      expect(result).to be_a(HiveAPI::Objects::ReturnRulesResponse)
      expect(result.send_back_address.postal_code).to eq("10115")
      expect(result.send_back_address.province_or_state_code).to eq("BE")
      expect(result.default_rules.a).to eq("restock")
      expect(result.default_rules.b).to eq("send_back")
      expect(result.default_rules.c).to eq("dispose")
      expect(result.sku_rules.first.sku.id).to eq(1001)
      expect(result.sku_rules.first.sku.sku_code).to eq("SKU-001")
      expect(result.sku_rules.first.a).to eq("send_back")
      expect(result.sku_rules.first.b).to be_nil
      expect(result.raw).to eq(response)
      expect(result.raw).to be_frozen
      expect(result.raw.fetch("send_back_address")).to be_frozen
      expect(result.raw.fetch("sku_rules")).to be_frozen
      expect(result.raw.fetch("sku_rules").first.fetch("sku")).to be_frozen
      expect(result).to be_frozen
      expect(result.send_back_address).to be_frozen
      expect(result.sku_rules.first).to be_frozen
    end

    it "preserves a null send-back address and empty SKU rules" do
      stub_request(:get, endpoint).to_return(
        status: 200,
        body: JSON.generate(
          "send_back_address" => nil,
          "default_rules" => {"A" => nil, "B" => nil, "C" => nil},
          "sku_rules" => []
        )
      )

      result = return_rules.get

      expect(result.send_back_address).to be_nil
      expect(result.sku_rules).to eq([])
      expect(result.sku_rules).to be_frozen
    end

    it "propagates typed HTTP errors" do
      stub_request(:get, endpoint).to_return(
        status: 401,
        body: JSON.generate("errors" => ["Invalid token"]),
        headers: {"Content-Type" => "application/json"}
      )

      expect { return_rules.get }.to raise_error(HiveAPI::AuthenticationError)
    end

    it "propagates typed transport errors" do
      stub_request(:get, endpoint).to_raise(Faraday::TimeoutError.new("timed out"))

      expect { return_rules.get }.to raise_error(HiveAPI::APIError) do |error|
        expect(error.cause).to be_a(Faraday::TimeoutError)
      end
    end
  end
end
