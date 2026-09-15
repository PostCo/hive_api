# frozen_string_literal: true

require "json"

RSpec.describe HiveAPI::Resource do
  let(:resource_class) do
    Class.new(described_class) do
      def fetch(path, params: {}, headers: {})
        get_request(path, params: params, headers: headers)
      end

      def create(path, body:, headers: {})
        post_request(path, body: body, headers: headers)
      end
    end
  end

  subject(:resource) { resource_class.new(client) }

  let(:client) { HiveAPI::Client.new(environment: :staging) }

  it "retains its client" do
    expect(resource.client).to be(client)
  end

  it "returns JSON parsed by Faraday for a JSON content type" do
    stub_request(:get, endpoint("returns/return-123"))
      .to_return(
        status: 200,
        body: JSON.generate("returnId" => "return-123"),
        headers: {"Content-Type" => "application/json"}
      )

    expect(resource.fetch("returns/return-123")).to eq("returnId" => "return-123")
  end

  it "falls back to parsing JSON served with an incorrect content type" do
    stub_request(:get, endpoint("returns"))
      .to_return(
        status: 200,
        body: JSON.generate("returns" => []),
        headers: {"Content-Type" => "text/plain"}
      )

    expect(resource.fetch("returns")).to eq("returns" => [])
  end

  it "preserves a non-JSON response body" do
    stub_request(:get, endpoint("health"))
      .to_return(status: 200, body: "healthy", headers: {"Content-Type" => "text/plain"})

    expect(resource.fetch("health")).to eq("healthy")
  end

  it "sends JSON POST bodies and caller headers through the connection" do
    payload = {"returnId" => "return-123"}
    stub_request(:post, endpoint("returns"))
      .with(
        body: JSON.generate(payload),
        headers: {
          "Content-Type" => "application/json",
          "X-Request-ID" => "request-123"
        }
      )
      .to_return(status: 201, body: JSON.generate("created" => true))

    expect(
      resource.create("returns", body: payload, headers: {"X-Request-ID" => "request-123"})
    ).to eq("created" => true)
  end

  def endpoint(path)
    "#{HiveAPI::Client::STAGING_BASE_URL}#{path}"
  end
end
