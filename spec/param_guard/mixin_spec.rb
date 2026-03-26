# frozen_string_literal: true

require "spec_helper"

# Simulate a Rails controller using the mixin
class BookingsController
  include ParamGuard

  def create(params)
    validate_params(params) do
      required(:date).type(:date)
      optional(:latitude).type(:float).range(-90.0..90.0)
      optional(:longitude).type(:float).range(-180.0..180.0)
      optional(:guests).type(:integer).range(1..20)
      optional(:status).inclusion(%w[pending confirmed cancelled])
    end
  end
end

# Simulate a service object using the mixin
class ReservationService
  include ParamGuard

  def call(params)
    validate_params(params) do
      required(:date).type(:date)
      required(:user_id).type(:integer)
    end
  end
end

RSpec.describe "ParamGuard::Mixin integration" do
  let(:controller) { BookingsController.new }
  let(:service)    { ReservationService.new }

  context "BookingsController#create" do
    it "returns coerced params for a valid request" do
      result = controller.create(
        date: "2024-09-01",
        latitude: "40.7",
        longitude: "-74.0",
        guests: "2",
        status: "pending"
      )

      expect(result[:date]).to eq(Date.new(2024, 9, 1))
      expect(result[:latitude]).to eq(40.7)
      expect(result[:guests]).to eq(2)
      expect(result[:status]).to eq("pending")
    end

    it "raises ValidationError when date is missing" do
      expect { controller.create({}) }
        .to raise_error(ParamGuard::ValidationError) { |e|
          expect(e.errors[:date]).to include("is required")
        }
    end

    it "raises ValidationError when latitude is out of range" do
      expect {
        controller.create(date: "2024-01-01", latitude: "200")
      }.to raise_error(ParamGuard::ValidationError) { |e|
        expect(e.errors[:latitude]).to include("must be in range -90.0..90.0")
      }
    end

    it "raises ValidationError when status is not in inclusion list" do
      expect {
        controller.create(date: "2024-01-01", status: "unknown")
      }.to raise_error(ParamGuard::ValidationError) { |e|
        expect(e.errors[:status]).to include(match(/must be one of/))
      }
    end

    it "aggregates multiple errors in one raise" do
      expect {
        controller.create(date: "bad-date", latitude: "999", guests: "abc")
      }.to raise_error(ParamGuard::ValidationError) { |e|
        expect(e.errors.keys).to include(:date, :latitude, :guests)
      }
    end
  end

  context "ReservationService#call" do
    it "validates required fields in a service object" do
      result = service.call(date: "2025-03-10", user_id: "99")
      expect(result[:date]).to eq(Date.new(2025, 3, 10))
      expect(result[:user_id]).to eq(99)
    end

    it "raises when user_id is missing" do
      expect { service.call(date: "2025-03-10") }
        .to raise_error(ParamGuard::ValidationError) { |e|
          expect(e.errors[:user_id]).to include("is required")
        }
    end
  end

  context "include ParamGuard shorthand" do
    it "adds validate_params directly via ParamGuard (not ParamGuard::Mixin)" do
      klass = Class.new { include ParamGuard }
      instance = klass.new
      result = instance.validate_params(date: "2024-01-15") do
        required(:date).type(:date)
      end
      expect(result[:date]).to eq(Date.new(2024, 1, 15))
    end
  end
end
