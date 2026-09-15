# frozen_string_literal: true

require "json"

RSpec.describe HiveAPI::Client do
  describe "environment selection" do
    {
      production: described_class::PRODUCTION_BASE_URL,
      staging: described_class::STAGING_BASE_URL,
      mock: described_class::MOCK_BASE_URL
    }.each do |environment, base_url|
      it "uses the fixed #{environment} base URL" do
        client = described_class.new(environment: environment)

        expect(client.environment).to eq(environment)
        expect(client.base_url).to eq(base_url)
        expect(client.connection.url_prefix.to_s).to eq(base_url)
      end
    end

    it "defaults to production" do
      client = described_class.new

      expect(client.environment).to eq(:production)
      expect(client.base_url).to eq(described_class::PRODUCTION_BASE_URL)
    end

    it "accepts an environment name as a string" do
      expect(described_class.new(environment: "staging").environment).to eq(:staging)
    end

    it "rejects any environment outside the fixed set" do
      expect { described_class.new(environment: "https://example.test") }
        .to raise_error(ArgumentError, /production, staging, mock/)
    end

    it "does not accept a caller-supplied base URL" do
      expect { described_class.new(base_url: "https://example.test") }
        .to raise_error(ArgumentError, /unknown keyword: :base_url/)
    end
  end

  describe "#connection" do
    subject(:client) { described_class.new }

    it "builds the connection lazily" do
      expect(client.instance_variable_defined?(:@connection)).to be(false)

      client.connection

      expect(client.instance_variable_defined?(:@connection)).to be(true)
    end

    it "memoizes the connection" do
      expect(client.connection).to be(client.connection)
    end

    it "sets bounded default timeouts" do
      expect(client.connection.options.open_timeout).to eq(described_class::DEFAULT_OPEN_TIMEOUT)
      expect(client.connection.options.timeout).to eq(described_class::DEFAULT_TIMEOUT)
    end

    it "accepts explicit timeout values" do
      client = described_class.new(open_timeout: 1, timeout: 3)

      expect(client.connection.options.open_timeout).to eq(1)
      expect(client.connection.options.timeout).to eq(3)
    end

    it "uses JSON request middleware and parses JSON response content types" do
      stub_request(:post, endpoint("echo"))
        .with(
          body: JSON.generate("returnId" => "return-123"),
          headers: {
            "Accept" => "application/json",
            "Content-Type" => "application/json"
          }
        )
        .to_return(
          status: 200,
          body: JSON.generate("returnId" => "return-123"),
          headers: {"Content-Type" => "application/json; charset=utf-8"}
        )

      response = client.connection.post("echo", returnId: "return-123")

      expect(response.body).to eq("returnId" => "return-123")
    end

    it "does not parse JSON when the response content type is not JSON" do
      body = JSON.generate("status" => "ok")
      stub_request(:get, endpoint("plain"))
        .to_return(status: 200, body: body, headers: {"Content-Type" => "text/plain"})

      expect(client.connection.get("plain").body).to eq(body)
    end
  end

  describe "adapter injection" do
    it "uses Faraday's default adapter by default" do
      expect(described_class.new.adapter).to eq(Faraday.default_adapter)
    end

    it "configures an injected adapter" do
      client = described_class.new(adapter: :test)

      expect(client.connection.builder.adapter.klass).to eq(Faraday::Adapter::Test)
    end
  end

  def endpoint(path)
    "#{described_class::PRODUCTION_BASE_URL}#{path}"
  end
end
