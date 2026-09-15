# HiveAPI

Rails-independent Ruby client foundation for the [Hive Merchant API](https://developers.hive.app/).

## Installation

Add the gem to your Gemfile:

```ruby
gem "hive_api", "~> 0.1.0"
```

Then run `bundle install`.

## Usage

Require the gem and build a client. It defaults to Hive's staging API:

```ruby
require "hive_api"

client = HiveAPI::Client.new

# Use the production API explicitly:
HiveAPI::Client.new(sandbox: false)
```

The client does not accept a custom base URL and it does not use global configuration. Connections use bounded connect and request timeouts, defaulting to 5 and 15 seconds respectively:

```ruby
HiveAPI::Client.new(
  sandbox: true,
  open_timeout: 2,
  timeout: 10
)
```

Authentication and concrete Hive resources will be added in subsequent releases.

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

## Development

```sh
bundle install
bundle exec rake
gem build hive_api.gemspec
```

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
