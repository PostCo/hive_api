# frozen_string_literal: true

require "json"

RSpec.describe HiveAPI::Client do
  let(:api_token) { "merchant-api-token" }

  describe "environment selection" do
    it "defaults to the staging API" do
      client = described_class.new(api_token: api_token)

      expect(client.connection.url_prefix.to_s).to eq(described_class::TEST_BASE_URL)
    end

    it "uses the staging API in sandbox mode" do
      client = described_class.new(api_token: api_token, sandbox: true)

      expect(client.connection.url_prefix.to_s).to eq(described_class::TEST_BASE_URL)
    end

    it "uses the production API outside sandbox mode" do
      client = described_class.new(api_token: api_token, sandbox: false)

      expect(client.connection.url_prefix.to_s).to eq(described_class::LIVE_BASE_URL)
    end

    it "does not accept a caller-supplied base URL" do
      expect { described_class.new(api_token: api_token, base_url: "https://example.test") }
        .to raise_error(ArgumentError, /unknown keyword: :base_url/)
    end
  end

  describe "authentication" do
    it "requires an API token" do
      expect { described_class.new }.to raise_error(ArgumentError, /api_token/)
    end

    [nil, "", "  "].each do |invalid_token|
      it "rejects #{invalid_token.inspect} as an API token" do
        expect { described_class.new(api_token: invalid_token) }
          .to raise_error(ArgumentError, "api_token must be a non-empty String")
      end
    end

    {
      true => described_class::TEST_BASE_URL,
      false => described_class::LIVE_BASE_URL
    }.each do |sandbox, base_url|
      it "sends only bearer authentication with sandbox: #{sandbox}" do
        request = stub_request(:get, "#{base_url}return_rules")
          .with(
            headers: {
              "Accept" => "application/json",
              "Authorization" => "Bearer #{api_token}"
            }
          )
          .to_return(status: 200, body: JSON.generate("data" => []))

        described_class.new(api_token: api_token, sandbox: sandbox)
          .connection.get("return_rules")

        expect(request).to have_been_requested.once
      end
    end
  end

  describe "#connection" do
    subject(:client) { described_class.new(api_token: api_token) }

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
      client = described_class.new(api_token: api_token, open_timeout: 1, timeout: 3)

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

    it "does not configure logging or retry middleware" do
      middleware = client.connection.builder.handlers.map { |handler| handler.klass.name }

      expect(middleware).not_to include("Faraday::Response::Logger", "Faraday::Retry::Middleware")
    end
  end

  describe "resources" do
    subject(:client) { described_class.new(api_token: api_token) }

    it "memoizes the return rules resource" do
      expect(client.return_rules).to be_a(HiveAPI::ReturnRulesResource)
      expect(client.return_rules).to be(client.return_rules)
    end

    it "memoizes the returns resource" do
      expect(client.returns).to be_a(HiveAPI::ReturnsResource)
      expect(client.returns).to be(client.returns)
    end
  end

  describe "adapter injection" do
    it "uses Faraday's default adapter by default" do
      expect(described_class.new(api_token: api_token).adapter).to eq(Faraday.default_adapter)
    end

    it "configures an injected adapter" do
      client = described_class.new(api_token: api_token, adapter: :test)

      expect(client.connection.builder.adapter.klass).to eq(Faraday::Adapter::Test)
    end
  end

  def endpoint(path)
    "#{described_class::TEST_BASE_URL}#{path}"
  end
end
