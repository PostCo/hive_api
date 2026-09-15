# frozen_string_literal: true

require "json"

RSpec.describe HiveAPI::ReturnsResource do
  subject(:returns) { client.returns }

  let(:api_token) { "returns-api-token" }
  let(:client) { HiveAPI::Client.new(api_token: api_token) }
  let(:endpoint) { "#{HiveAPI::Client::TEST_BASE_URL}returns" }
  let(:return_payload) do
    {
      "id" => 5555,
      "announced_items" => [
        {
          "id" => 11,
          "quantity" => 2,
          "sku" => {"id" => 1001, "sku_code" => "SKU-001"},
          "customer_return_reason" => "Too small",
          "customer_return_message" => "The item did not fit."
        }
      ],
      "carrier" => "DHL",
      "completed_handling_at" => "2026-09-12T15:00:00Z",
      "created_at" => "2026-09-10T10:00:00Z",
      "handled_items" => [
        {
          "id" => 21,
          "quantity" => 1,
          "sku" => {"id" => 1001, "sku_code" => "SKU-001"},
          "condition" => "A",
          "follow_up_action" => "restock",
          "inventory_batch_id" => 12345,
          "return_item_id" => 11,
          "photos" => [{"id" => 31, "image_url" => "https://cdn.hive.app/item.jpg"}]
        }
      ],
      "order" => {
        "id" => 123456,
        "merchant_order_id" => "ORD-1001",
        "customer_order_number" => "CUSTOMER-1001"
      },
      "photos" => [
        {"id" => 41, "image_url" => "https://cdn.hive.app/return.jpg", "photo_type" => "inside"}
      ],
      "received_at" => "2026-09-11T12:00:00Z",
      "return_reason" => "customer_return",
      "return_reason_type" => "active",
      "started_processing_at" => "2026-09-11T13:00:00Z",
      "status" => "handling_completed",
      "tracking_code" => "TRACK-RET-123",
      "tracking_url" => "https://dhl.example/track/TRACK-RET-123",
      "updated_at" => "2026-09-12T15:00:00Z"
    }
  end

  describe "#list" do
    it "serializes every documented filter without changing caller values" do
      request = stub_request(:get, endpoint)
        .with(
          query: {
            "sales_channel_id[in]" => "101,202",
            "created_at[gt]" => "2026-09-01T00:00:00+08:00",
            "created_at[lt]" => "2026-10-01T00:00:00+08:00",
            "created_at[gte]" => "2026-09-02T00:00:00Z",
            "created_at[lte]" => "2026-09-30T23:59:59Z",
            "limit" => "37"
          },
          headers: {
            "Accept" => "application/json",
            "Authorization" => "Bearer #{api_token}"
          }
        )
        .to_return(status: 200, body: JSON.generate(list_response))

      returns.list(
        sales_channel_id_in: [101, 202],
        created_at_gt: "2026-09-01T00:00:00+08:00",
        created_at_lt: "2026-10-01T00:00:00+08:00",
        created_at_gte: "2026-09-02T00:00:00Z",
        created_at_lte: "2026-09-30T23:59:59Z",
        limit: 37
      )

      expect(request).to have_been_requested.once
    end

    it "passes a pre-serialized sales channel filter through unchanged" do
      request = stub_request(:get, endpoint)
        .with(query: {"sales_channel_id[in]" => "101,202"})
        .to_return(status: 200, body: JSON.generate(list_response))

      returns.list(sales_channel_id_in: "101,202")

      expect(request).to have_been_requested.once
    end

    it "omits nil filters while preserving zero" do
      request = stub_request(:get, endpoint)
        .with(query: {"limit" => "0"})
        .to_return(status: 200, body: JSON.generate(list_response))

      returns.list(limit: 0)

      expect(request).to have_been_requested.once
    end

    it "maps every return and the pagination evidence into dedicated immutable responses" do
      response = list_response
      stub_request(:get, endpoint).to_return(status: 200, body: JSON.generate(response))

      result = returns.list

      expect(result).to be_a(HiveAPI::Objects::ReturnListResponse)
      expect(result.data.map(&:class)).to eq([HiveAPI::Objects::ReturnResponse])
      expect(result.data.first.id).to eq(5555)
      expect(result.data.first.order.merchant_order_id).to eq("ORD-1001")
      expect(result.data.first.raw).to eq(return_payload)
      expect(result.data.first.raw.fetch("handled_items").first).to be_frozen
      expect(result.pagination).to be_a(HiveAPI::Objects::PaginationResponse)
      expect(result.pagination.first_page_url).to eq("#{endpoint}?limit=20")
      expect(result.pagination.limit).to eq(20)
      expect(result.pagination.next_page_url).to eq("#{endpoint}?limit=20&page=cursor-2")
      expect(result.pagination.raw).to eq(response.fetch("pagination"))
      expect(result.raw).to eq(response)
      expect(result.raw).to be_frozen
      expect(result.raw.fetch("data")).to be_frozen
      expect(result.raw.fetch("data").first.fetch("handled_items").first.fetch("photos")).to be_frozen
      expect(result).to be_frozen
      expect(result.data).to be_frozen
      expect(result.data.first).to be_frozen
      expect(result.pagination).to be_frozen
    end

    it "preserves an empty collection and terminal pagination" do
      response = list_response(data: [], next_page_url: nil)
      stub_request(:get, endpoint).to_return(status: 200, body: JSON.generate(response))

      result = returns.list

      expect(result.data).to eq([])
      expect(result.data).to be_frozen
      expect(result.pagination.next_page_url).to be_nil
    end

    it "fetches only the first page unless traversal is requested explicitly" do
      request = stub_request(:get, endpoint)
        .to_return(status: 200, body: JSON.generate(list_response))

      returns.list

      expect(request).to have_been_requested.once
    end

    it "propagates typed HTTP errors" do
      stub_request(:get, endpoint).to_return(
        status: 429,
        body: JSON.generate("errors" => ["Too many requests"]),
        headers: {"Content-Type" => "application/json"}
      )

      expect { returns.list }.to raise_error(HiveAPI::RateLimitError)
    end

    it "propagates typed transport errors" do
      stub_request(:get, endpoint).to_raise(Faraday::ConnectionFailed.new("closed"))

      expect { returns.list }.to raise_error(HiveAPI::APIError) do |error|
        expect(error.cause).to be_a(Faraday::ConnectionFailed)
      end
    end
  end

  describe "#list_page" do
    it "follows a provider page URL on the selected Hive origin and exact Returns path" do
      page_url = "#{endpoint}?limit=20&page=provider-cursor"
      request = stub_request(:get, page_url)
        .with(headers: {"Authorization" => "Bearer #{api_token}"})
        .to_return(status: 200, body: JSON.generate(list_response(next_page_url: nil)))

      result = returns.list_page(url: page_url)

      expect(request).to have_been_requested.once
      expect(result).to be_a(HiveAPI::Objects::ReturnListResponse)
      expect(result.pagination.next_page_url).to be_nil
    end

    {
      "another origin" => "https://attacker.example/merchant_api/v2/returns?page=cursor",
      "the other Hive environment" => "#{HiveAPI::Client::LIVE_BASE_URL}returns?page=cursor",
      "a sibling Hive path" => "#{HiveAPI::Client::TEST_BASE_URL}orders?page=cursor",
      "a return member path" => "#{HiveAPI::Client::TEST_BASE_URL}returns/5555?page=cursor",
      "embedded credentials" => "https://user:secret@staging.app.hive.app/merchant_api/v2/returns?page=cursor",
      "a fragment" => "#{HiveAPI::Client::TEST_BASE_URL}returns?page=cursor#fragment",
      "a relative URL" => "returns?page=cursor"
    }.each do |description, unsafe_url|
      it "rejects #{description}" do
        expect { returns.list_page(url: unsafe_url) }
          .to raise_error(ArgumentError, described_class::INVALID_PAGE_URL_MESSAGE)
        expect(a_request(:get, /.*/)).not_to have_been_made
      end
    end

    it "rejects malformed and nil URLs" do
      ["not a url%", nil].each do |unsafe_url|
        expect { returns.list_page(url: unsafe_url) }
          .to raise_error(ArgumentError, described_class::INVALID_PAGE_URL_MESSAGE)
      end
    end

    it "propagates typed HTTP errors" do
      page_url = "#{endpoint}?page=expired-cursor"
      stub_request(:get, page_url).to_return(
        status: 400,
        body: JSON.generate("errors" => ["Invalid cursor"]),
        headers: {"Content-Type" => "application/json"}
      )

      expect { returns.list_page(url: page_url) }.to raise_error(HiveAPI::ValidationError)
    end

    it "propagates typed transport errors" do
      page_url = "#{endpoint}?page=cursor"
      stub_request(:get, page_url).to_raise(Faraday::TimeoutError.new("timed out"))

      expect { returns.list_page(url: page_url) }.to raise_error(HiveAPI::APIError) do |error|
        expect(error.cause).to be_a(Faraday::TimeoutError)
      end
    end
  end

  describe "#find" do
    it "gets and maps the complete documented return structure" do
      request = stub_request(:get, "#{endpoint}/5555")
        .with(headers: {
          "Accept" => "application/json",
          "Authorization" => "Bearer #{api_token}"
        })
        .to_return(status: 200, body: JSON.generate(return_payload))

      result = returns.find(id: 5555)

      expect(request).to have_been_requested.once
      expect(result).to be_a(HiveAPI::Objects::ReturnResponse)
      expect(result.id).to eq(5555)
      expect(result.order.id).to eq(123456)
      expect(result.order.merchant_order_id).to eq("ORD-1001")
      expect(result.order.customer_order_number).to eq("CUSTOMER-1001")
      expect(result.carrier).to eq("DHL")
      expect(result.tracking_code).to eq("TRACK-RET-123")
      expect(result.tracking_url).to eq("https://dhl.example/track/TRACK-RET-123")
      expect(result.announced_items.first.quantity).to eq(2)
      expect(result.announced_items.first.customer_return_reason).to eq("Too small")
      expect(result.announced_items.first.customer_return_message).to eq("The item did not fit.")
      expect(result.announced_items.first.sku.id).to eq(1001)
      expect(result.announced_items.first.sku.sku_code).to eq("SKU-001")
      expect(result.handled_items.first.quantity).to eq(1)
      expect(result.handled_items.first.condition).to eq("A")
      expect(result.handled_items.first.follow_up_action).to eq("restock")
      expect(result.handled_items.first.inventory_batch_id).to eq(12345)
      expect(result.handled_items.first.return_item_id).to eq(11)
      expect(result.handled_items.first.photos.first.image_url).to eq("https://cdn.hive.app/item.jpg")
      expect(result.photos.first.photo_type).to eq("inside")
      expect(result.return_reason).to eq("customer_return")
      expect(result.return_reason_type).to eq("active")
      expect(result.received_at).to eq("2026-09-11T12:00:00Z")
      expect(result.started_processing_at).to eq("2026-09-11T13:00:00Z")
      expect(result.completed_handling_at).to eq("2026-09-12T15:00:00Z")
      expect(result.created_at).to eq("2026-09-10T10:00:00Z")
      expect(result.updated_at).to eq("2026-09-12T15:00:00Z")
      expect(result.status).to eq("handling_completed")
      expect(result.raw).to eq(return_payload)
      expect(result.raw).to be_frozen
      expect(result.raw.fetch("handled_items").first.fetch("photos").first).to be_frozen
    end

    it "preserves nullable tracking, timing, reason, and collection fields" do
      response = return_payload.merge(
        "carrier" => nil,
        "completed_handling_at" => nil,
        "handled_items" => [],
        "photos" => [],
        "received_at" => nil,
        "return_reason" => nil,
        "return_reason_type" => nil,
        "started_processing_at" => nil,
        "tracking_code" => nil,
        "tracking_url" => nil
      )
      stub_request(:get, "#{endpoint}/5555")
        .to_return(status: 200, body: JSON.generate(response))

      result = returns.find(id: 5555)

      expect(result.carrier).to be_nil
      expect(result.handled_items).to eq([])
      expect(result.photos).to eq([])
      expect(result.tracking_code).to be_nil
      expect(result.return_reason).to be_nil
    end

    it "propagates typed HTTP errors" do
      stub_request(:get, "#{endpoint}/missing").to_return(
        status: 404,
        body: JSON.generate("errors" => ["Return not found"]),
        headers: {"Content-Type" => "application/json"}
      )

      expect { returns.find(id: "missing") }.to raise_error(HiveAPI::NotFoundError)
    end

    it "propagates typed transport errors" do
      stub_request(:get, "#{endpoint}/5555").to_raise(Faraday::ConnectionFailed.new("closed"))

      expect { returns.find(id: 5555) }.to raise_error(HiveAPI::APIError) do |error|
        expect(error.cause).to be_a(Faraday::ConnectionFailed)
      end
    end
  end

  def list_response(data: [return_payload], next_page_url: "#{endpoint}?limit=20&page=cursor-2")
    {
      "data" => data,
      "pagination" => {
        "first_page_url" => "#{endpoint}?limit=20",
        "limit" => 20,
        "next_page_url" => next_page_url
      }
    }
  end
end
