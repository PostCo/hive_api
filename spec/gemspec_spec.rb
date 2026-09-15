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

  it "uses the PostCo development toolchain" do
    expect(specification.development_dependencies.map(&:name).sort)
      .to eq(%w[rake rspec standard webmock])
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
  end
end
