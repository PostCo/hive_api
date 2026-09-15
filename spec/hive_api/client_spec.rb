# frozen_string_literal: true

require "json"

RSpec.describe HiveAPI::Client do
  describe "environment selection" do
    it "defaults to the staging API" do
      client = described_class.new

      expect(client.connection.url_prefix.to_s).to eq(described_class::TEST_BASE_URL)
    end

    it "uses the staging API in sandbox mode" do
      client = described_class.new(sandbox: true)

      expect(client.connection.url_prefix.to_s).to eq(described_class::TEST_BASE_URL)
    end

    it "uses the production API outside sandbox mode" do
      client = described_class.new(sandbox: false)

      expect(client.connection.url_prefix.to_s).to eq(described_class::LIVE_BASE_URL)
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
    "#{described_class::TEST_BASE_URL}#{path}"
  end
end
