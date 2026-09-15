# frozen_string_literal: true

require "json"
require "stringio"

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

  let(:api_token) { "resource-api-token" }
  let(:client) { HiveAPI::Client.new(api_token: api_token) }

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

  describe "HTTP failures" do
    {
      400 => [HiveAPI::ValidationError, "Bad request"],
      401 => [HiveAPI::AuthenticationError, "Authentication failed"],
      403 => [HiveAPI::AuthenticationError, "Authentication failed"],
      404 => [HiveAPI::NotFoundError, "Resource not found"],
      429 => [HiveAPI::RateLimitError, "Rate limited"],
      500 => [HiveAPI::ServerError, "Server error"],
      502 => [HiveAPI::ServerError, "Server error"],
      599 => [HiveAPI::ServerError, "Server error"],
      422 => [HiveAPI::APIError, "API error"]
    }.each do |status, (error_class, prefix)|
      it "maps HTTP #{status} to #{error_class}" do
        stub_request(:get, endpoint("failure"))
          .to_return(
            status: status,
            body: JSON.generate("errors" => ["Provider failure"]),
            headers: {"Content-Type" => "application/json"}
          )

        expect { resource.fetch("failure") }
          .to raise_error(error_class) do |error|
            expect(error.message).to eq("#{prefix} (HTTP #{status}): Provider failure")
            expect(error.status_code).to eq(status)
            expect(error.response.status).to eq(status)
          end
      end
    end

    it "uses only string entries from Hive's documented errors field" do
      stub_request(:get, endpoint("invalid"))
        .to_return(
          status: 400,
          body: JSON.generate(
            "errors" => ["Invalid return", {"api_token" => api_token}, 123]
          ),
          headers: {"Content-Type" => "application/json"}
        )

      expect { resource.fetch("invalid") }
        .to raise_error(HiveAPI::ValidationError) do |error|
          expect(error.message).to eq("Bad request (HTTP 400): Invalid return")
        end
    end

    it "supports approved scalar message and error fields" do
      stub_request(:get, endpoint("missing"))
        .to_return(
          status: 404,
          body: JSON.generate("message" => "Return missing"),
          headers: {"Content-Type" => "application/json"}
        )

      expect { resource.fetch("missing") }
        .to raise_error(HiveAPI::NotFoundError, "Resource not found (HTTP 404): Return missing")
    end

    it "exposes Hive rate-limit metadata using numeric values" do
      stub_request(:get, endpoint("rate-limited"))
        .to_return(
          status: 429,
          body: JSON.generate("errors" => ["Too many requests"]),
          headers: {
            "Content-Type" => "application/json",
            "X-Rate-Limit-Used" => "42",
            "X-Rate-Limit-Max" => "100",
            "Retry-After" => "3.2"
          }
        )

      expect { resource.fetch("rate-limited") }
        .to raise_error(HiveAPI::RateLimitError) do |error|
          expect(error.rate_limit_used).to eq(42)
          expect(error.rate_limit_max).to eq(100)
          expect(error.retry_after).to eq(3.2)
        end
    end

    it "does not interpolate unapproved structured response fields" do
      stub_request(:get, endpoint("unsafe-error"))
        .to_return(
          status: 500,
          body: JSON.generate(
            "error" => {"api_token" => api_token},
            "authorization" => "Bearer #{api_token}",
            "response" => {"secret" => api_token}
          ),
          headers: {"Content-Type" => "application/json"}
        )

      expect { resource.fetch("unsafe-error") }
        .to raise_error(HiveAPI::ServerError) do |error|
          expect(error.message).to eq("Server error (HTTP 500): Unknown error")
          expect(error.message).not_to include(api_token, "Authorization", "Bearer")
        end
    end

    it "redacts credentials echoed by an approved provider field" do
      stub_request(:get, endpoint("echoed-credential"))
        .to_return(
          status: 401,
          body: JSON.generate(
            "errors" => ["Authorization: Bearer #{api_token}; token=#{api_token}"]
          ),
          headers: {"Content-Type" => "application/json"}
        )

      expect { resource.fetch("echoed-credential") }
        .to raise_error(HiveAPI::AuthenticationError) do |error|
          expect(error.message).not_to include(api_token, "Authorization", "Bearer")
          expect(error.message).to include("[REDACTED]")
        end
    end
  end

  describe "transport failures" do
    it "maps Faraday timeouts to APIError and retains the original cause" do
      stub_request(:get, endpoint("slow"))
        .to_raise(Faraday::TimeoutError.new("execution expired"))

      expect { resource.fetch("slow") }
        .to raise_error(HiveAPI::APIError) do |error|
          expect(error.message).to eq("Network request failed")
          expect(error.status_code).to be_nil
          expect(error.response).to be_nil
          expect(error.cause).to be_a(Faraday::TimeoutError)
        end
    end

    it "maps connection failures to APIError and retains the original cause" do
      stub_request(:get, endpoint("unavailable"))
        .to_raise(Faraday::ConnectionFailed.new("socket closed"))

      expect { resource.fetch("unavailable") }
        .to raise_error(HiveAPI::APIError) do |error|
          expect(error.message).to eq("Network request failed")
          expect(error.cause).to be_a(Faraday::ConnectionFailed)
        end
    end

    it "maps other Faraday failures to the generic API error" do
      stub_request(:get, endpoint("broken"))
        .to_raise(Faraday::Error.new("unexpected transport failure"))

      expect { resource.fetch("broken") }
        .to raise_error(HiveAPI::APIError) do |error|
          expect(error.message).to eq("Network request failed")
          expect(error.cause).to be_a(Faraday::Error)
        end
    end

    it "does not retry or log a failed mutating request" do
      request = stub_request(:post, endpoint("returns"))
        .with(headers: {"Authorization" => "Bearer #{api_token}"})
        .to_raise(Faraday::ConnectionFailed.new("socket closed"))

      error, output = capture_failure do
        resource.create("returns", body: {"returnId" => "return-123"})
      end

      expect(error).to be_a(HiveAPI::APIError)
      expect(request).to have_been_requested.once
      expect(output).to be_empty
    end
  end

  def endpoint(path)
    "#{HiveAPI::Client::TEST_BASE_URL}#{path}"
  end

  def capture_failure
    stdout = StringIO.new
    stderr = StringIO.new
    original_stdout = $stdout
    original_stderr = $stderr
    error = nil

    begin
      $stdout = stdout
      $stderr = stderr
      yield
    rescue HiveAPI::Error => caught_error
      error = caught_error
    ensure
      $stdout = original_stdout
      $stderr = original_stderr
    end

    [error, stdout.string + stderr.string]
  end
end
