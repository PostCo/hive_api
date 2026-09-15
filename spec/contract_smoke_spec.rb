# frozen_string_literal: true

require "stringio"
require_relative "../script/contract_smoke"

RSpec.describe HiveAPI::ContractSmoke do
  let(:return_rules) { instance_double(HiveAPI::ReturnRulesResource) }
  let(:returns) { instance_double(HiveAPI::ReturnsResource) }
  let(:client) { instance_double(HiveAPI::Client, return_rules: return_rules, returns: returns) }
  let(:output) { StringIO.new }

  it "checks all three read contracts when staging contains a return" do
    page = HiveAPI::Objects::ReturnListResponse.new("data" => [{"id" => 5555}])

    expect(return_rules).to receive(:get)
    expect(returns).to receive(:list).with(limit: 1).and_return(page)
    expect(returns).to receive(:find).with(id: 5555)

    described_class.new(client: client, output: output).run

    expect(output.string).to eq(<<~OUTPUT)
      PASS GET /return_rules
      PASS GET /returns
      PASS GET /returns/{id}
    OUTPUT
  end

  it "reports the no-data limitation without attempting member retrieval" do
    page = HiveAPI::Objects::ReturnListResponse.new("data" => [])

    allow(return_rules).to receive(:get)
    allow(returns).to receive(:list).with(limit: 1).and_return(page)
    expect(returns).not_to receive(:find)

    described_class.new(client: client, output: output).run

    expect(output.string).to include("SKIP GET /returns/{id}: staging returned no data")
  end
end
