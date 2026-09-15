# HiveAPI

Rails-independent Ruby client foundation for the [Hive Merchant API](https://developers.hive.app/).

## Installation

Add the gem to your Gemfile:

```ruby
gem "hive_api", "~> 0.1.0"
```

Then run `bundle install`.

## Usage

### Initialize a client

Require the gem and build a client. It defaults to Hive's staging API:

```ruby
require "hive_api"

client = HiveAPI::Client.new(
  api_token: ENV.fetch("HIVE_API_TOKEN"),
  sandbox: true # Staging (the default)
)

# Select production explicitly:
production_client = HiveAPI::Client.new(
  api_token: ENV.fetch("HIVE_API_TOKEN"),
  sandbox: false
)
```

The client does not accept a custom base URL and it does not use global configuration. Connections use bounded connect and request timeouts, defaulting to 5 and 15 seconds respectively:

```ruby
HiveAPI::Client.new(
  api_token: ENV.fetch("HIVE_API_TOKEN"),
  sandbox: true,
  open_timeout: 2,
  timeout: 10
)
```

Every request sends the API token as a bearer credential in the `Authorization` header. The gem
does not acquire, refresh, rotate, log, or retry credentials or requests automatically.

### Response objects

Response objects expose provider keys as snake-case Ruby methods, including nested hashes and arrays. The original provider payload remains available as a deeply frozen snapshot through `raw`, while `to_h` returns plain recursive hashes and arrays.

```ruby
response = HiveAPI::Base.new(
  "returnId" => "return-123",
  "lineItems" => [{"merchantSKU" => "SKU-1"}]
)

response.return_id                     # => "return-123"
response.line_items.first.merchant_sku # => "SKU-1"
response.raw.frozen?                   # => true
response.to_h                          # => {"return_id" => "return-123", ...}
```

### Returns

The client exposes Hive's return rules and returns without applying merchant policy or traversing
pages automatically:

```ruby
# GET /return_rules
rules = client.return_rules.get
rules.send_back_address.postal_code
rules.default_rules.a
rules.sku_rules.first.sku.sku_code

# GET /returns
page = client.returns.list(
  sales_channel_id_in: [101, 202],
  created_at_gt: "2026-09-01T00:00:00Z",
  created_at_lt: "2026-10-01T00:00:00Z",
  created_at_gte: "2026-09-02T00:00:00Z",
  created_at_lte: "2026-09-30T23:59:59Z",
  limit: 50
)

page.data.each do |hive_return|
  hive_return.order.merchant_order_id
  hive_return.announced_items
  hive_return.handled_items
end

# GET /returns/{id}
hive_return = client.returns.find(id: 5555)
```

`sales_channel_id_in:` accepts either an array or a comma-separated value. The timestamp filters
are passed to Hive unchanged, so callers should provide ISO 8601 values with an explicit timezone.
Nil filters are omitted.

List responses expose `pagination.first_page_url`, `pagination.limit`, and
`pagination.next_page_url`. Fetch another page explicitly when Hive provides one:

```ruby
next_page = client.returns.list_page(url: page.pagination.next_page_url)
```

`list_page` only follows URLs on the client's selected Hive environment and exact Returns path.
All response objects are immutable and retain their deeply frozen provider payload through `raw`.

### Error handling

Unsuccessful responses raise a typed `HiveAPI::Error` subclass:

```ruby
begin
  client.returns.find(id: 5555)
rescue HiveAPI::AuthenticationError => error
  # 401/403 responses
  puts error.status_code
rescue HiveAPI::ValidationError => error
  # 400 responses
  puts error.status_code
rescue HiveAPI::NotFoundError => error
  # 404 responses
  puts error.status_code
rescue HiveAPI::RateLimitError => error
  # 429 responses
  puts error.retry_after
rescue HiveAPI::ServerError => error
  # 500-599 responses
  puts error.status_code
rescue HiveAPI::APIError => error
  # Other HTTP responses and transport failures
  warn error.message
end
```

Errors expose the HTTP status and Hive's `X-Rate-Limit-Used`, `X-Rate-Limit-Max`, and
`Retry-After` metadata when present. Transport failures retain the original Faraday exception as
their cause. Error messages redact bearer credentials and the configured token.

### Caller responsibilities

This gem is deliberately a thin API client. Webhook handling, automatic polling, retries, caching,
persistence, and business workflows remain caller-owned. In particular, callers decide when and
how to traverse subsequent pages; the gem never retries or polls automatically.

## Development

```sh
bundle install
bundle exec rake
bundle exec rake contract:smoke
gem build hive_api.gemspec
```

The contract smoke task makes read-only requests against staging. See [RELEASING.md](RELEASING.md)
for the credential-safe release workflow.

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
