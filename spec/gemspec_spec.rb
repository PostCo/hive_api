# frozen_string_literal: true

RSpec.describe "hive_api.gemspec" do
  subject(:specification) do
    Gem::Specification.load(File.expand_path("../hive_api.gemspec", __dir__))
  end

  it "requires compatible Ruby and the PostCo runtime dependencies" do
    expect(specification.required_ruby_version).to be_satisfied_by(Gem::Version.new("3.3.0"))
    expect(specification.runtime_dependencies.map(&:name).sort)
      .to eq(%w[activesupport faraday faraday-net_http])
  end

  it "describes the initial Returns API release" do
    expect(specification.name).to eq("hive_api")
    expect(specification.version.to_s).to eq("0.1.0")
    expect(specification.summary).to eq("Rails-independent Ruby client for Hive Returns")
    expect(specification.description).to include("return rules", "paginate returns", "individual returns")
  end

  it "uses the PostCo development toolchain" do
    expect(specification.development_dependencies.map(&:name).sort)
      .to eq(%w[rake rspec standard webmock])
  end

  it "publishes discoverable metadata and requires RubyGems MFA" do
    expect(specification.metadata).to include(
      "source_code_uri" => "https://github.com/PostCo/hive_api",
      "changelog_uri" => "https://github.com/PostCo/hive_api/blob/main/CHANGELOG.md",
      "rubygems_mfa_required" => "true"
    )
  end

  it "packages library files and project documentation" do
    expect(specification.files).to include(
      "lib/hive_api.rb",
      "lib/hive_api/client.rb",
      "README.md",
      "LICENSE.txt",
      "CHANGELOG.md"
    )
    expect(specification.files).not_to include(a_string_starting_with("spec/"))
    expect(specification.files).not_to include(a_string_starting_with("script/"))
    expect(specification.files).not_to include(a_string_matching(/(?:\.env|credentials|token|secret)/i))
  end
end
