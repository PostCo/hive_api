# frozen_string_literal: true

require "open3"
require "rbconfig"

RSpec.describe HiveAPI do
  it "has the initial release version" do
    expect(described_class::VERSION).to eq("0.1.0")
  end

  it "autoloads the public foundation" do
    expect(described_class::Client).to be_a(Class)
    expect(described_class::Base).to be < OpenStruct
    expect(described_class::Resource).to be_a(Class)
    expect(described_class::Error).to be < StandardError
    expect(described_class::APIError).to be < described_class::Error
    expect(described_class::AuthenticationError).to be < described_class::Error
    expect(described_class::ValidationError).to be < described_class::Error
    expect(described_class::NotFoundError).to be < described_class::Error
    expect(described_class::RateLimitError).to be < described_class::Error
    expect(described_class::ServerError).to be < described_class::Error
    expect(described_class::ReturnRulesResource).to be < described_class::Resource
    expect(described_class::ReturnsResource).to be < described_class::Resource
    expect(described_class::Objects).to be_a(Module)
    expect(described_class::Objects::PaginationResponse).to be < described_class::Base
    expect(described_class::Objects::ReturnListResponse).to be < described_class::Base
    expect(described_class::Objects::ReturnResponse).to be < described_class::Base
    expect(described_class::Objects::ReturnRulesResponse).to be < described_class::Base
  end

  it "does not expose global configuration" do
    expect(described_class).not_to respond_to(:configure)
    expect(described_class).not_to respond_to(:configuration)
    expect(described_class.const_defined?(:Configuration, false)).to be(false)
  end

  it "loads in a clean Ruby process without Rails or Zeitwerk" do
    script = <<~RUBY
      require "hive_api"
      HiveAPI::Client
      HiveAPI::Base
      HiveAPI::Resource
      HiveAPI::Error
      HiveAPI::APIError
      HiveAPI::AuthenticationError
      HiveAPI::ValidationError
      HiveAPI::NotFoundError
      HiveAPI::RateLimitError
      HiveAPI::ServerError
      HiveAPI::ReturnRulesResource
      HiveAPI::ReturnsResource
      HiveAPI::Objects::PaginationResponse
      HiveAPI::Objects::ReturnListResponse
      HiveAPI::Objects::ReturnResponse
      HiveAPI::Objects::ReturnRulesResponse
      abort "Rails loaded" if defined?(Rails)
      abort "Zeitwerk loaded" if defined?(Zeitwerk)
    RUBY

    _stdout, stderr, status = Open3.capture3(
      {"BUNDLE_GEMFILE" => nil, "RUBYOPT" => nil},
      RbConfig.ruby,
      "-I#{File.expand_path("../lib", __dir__)}",
      "-e",
      script
    )

    expect(status).to be_success, stderr
  end
end
