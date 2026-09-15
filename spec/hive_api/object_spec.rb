# frozen_string_literal: true

require "json"

RSpec.describe HiveAPI::Base do
  describe ".new" do
    it "maps a top-level array into response objects" do
      response = [{"returnId" => "one"}, {"returnId" => "two"}]

      result = described_class.new(response)

      expect(result.map(&:class)).to eq([described_class, described_class])
      expect(result.map(&:return_id)).to eq(%w[one two])
    end
  end

  describe "response access" do
    subject(:object) do
      described_class.new(
        "returnId" => "return-123",
        "sendBackAddress" => {"postalCode" => "10115"},
        "lineItems" => [{"merchantSKU" => "SKU-1"}]
      )
    end

    it "recursively exposes snake-case methods" do
      expect(object.return_id).to eq("return-123")
      expect(object.send_back_address.postal_code).to eq("10115")
      expect(object.line_items.first.merchant_sku).to eq("SKU-1")
    end

    it "retains a deeply frozen raw payload" do
      expect(object.raw).to be(object.original_response)
      expect(object.raw).to be_frozen
      expect(object.raw.fetch("sendBackAddress")).to be_frozen
      expect(object.raw.fetch("lineItems")).to be_frozen
      expect(object.raw.fetch("lineItems").first).to be_frozen
      expect(object.raw.fetch("returnId")).to be_frozen
    end
  end

  describe "hash conversion" do
    let(:object) do
      described_class.new(
        "returnId" => "return-123",
        "lineItems" => [{"merchantSKU" => "SKU-1"}]
      )
    end

    let(:expected_hash) do
      {
        "return_id" => "return-123",
        "line_items" => [{"merchant_sku" => "SKU-1"}]
      }
    end

    it "returns plain recursive structures from #to_h and #to_hash" do
      expect(object.to_h).to eq(expected_hash)
      expect(object.to_hash).to eq(expected_hash)
      expect(contains_ostruct?(object.to_h)).to be(false)
    end

    it "does not serialize OpenStruct table wrappers" do
      expect(JSON.generate(object.to_h)).not_to include('"table"')
    end
  end

  def contains_ostruct?(value)
    case value
    when OpenStruct
      true
    when Hash
      value.any? { |key, entry| contains_ostruct?(key) || contains_ostruct?(entry) }
    when Array
      value.any? { |entry| contains_ostruct?(entry) }
    else
      false
    end
  end
end
