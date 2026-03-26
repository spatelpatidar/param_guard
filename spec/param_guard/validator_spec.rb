# frozen_string_literal: true

require "spec_helper"

RSpec.describe ParamGuard::Validator do
  let(:valid_params) do
    { date: "2024-06-15", latitude: "45.5", longitude: "-73.5", guests: "3", status: "confirmed" }
  end

  # --- Happy path ---------------------------------------------------------

  describe "#validate! — success" do
    it "returns coerced values for all valid fields" do
      result = described_class.new(valid_params).tap { |v|
        v.instance_eval do
          required(:date).type(:date)
          optional(:latitude).type(:float).range(-90.0..90.0)
          optional(:longitude).type(:float).range(-180.0..180.0)
          optional(:guests).type(:integer).range(1..20)
          optional(:status).inclusion(%w[pending confirmed cancelled])
        end
      }.validate!

      expect(result[:date]).to eq(Date.new(2024, 6, 15))
      expect(result[:latitude]).to eq(45.5)
      expect(result[:longitude]).to eq(-73.5)
      expect(result[:guests]).to eq(3)
      expect(result[:status]).to eq("confirmed")
    end

    it "omits absent optional fields from the result" do
      result = described_class.new({ date: "2024-01-01" }).tap { |v|
        v.instance_eval do
          required(:date).type(:date)
          optional(:latitude).type(:float)
        end
      }.validate!

      expect(result).to have_key(:date)
      expect(result).not_to have_key(:latitude)
    end
  end

  # --- Validation errors --------------------------------------------------

  describe "#validate! — failure" do
    it "raises ValidationError listing all failed fields" do
      expect {
        described_class.new({}).tap { |v|
          v.instance_eval do
            required(:date).type(:date)
            required(:guests).type(:integer)
          end
        }.validate!
      }.to raise_error(ParamGuard::ValidationError) { |e|
        expect(e.errors).to have_key(:date)
        expect(e.errors).to have_key(:guests)
      }
    end

    it "collects errors from multiple failing fields at once" do
      expect {
        described_class.new({ date: "bad", latitude: "999" }).tap { |v|
          v.instance_eval do
            required(:date).type(:date)
            optional(:latitude).type(:float).range(-90.0..90.0)
          end
        }.validate!
      }.to raise_error(ParamGuard::ValidationError) { |e|
        expect(e.errors.keys).to contain_exactly(:date, :latitude)
      }
    end
  end

  # --- Params normalisation -----------------------------------------------

  describe "params normalisation" do
    it "accepts string-keyed hashes" do
      result = described_class.new({ "guests" => "4" }).tap { |v|
        v.instance_eval { required(:guests).type(:integer) }
      }.validate!

      expect(result[:guests]).to eq(4)
    end

    it "handles nil params gracefully" do
      expect {
        described_class.new(nil).tap { |v|
          v.instance_eval { required(:date).type(:date) }
        }.validate!
      }.to raise_error(ParamGuard::ValidationError)
    end

    it "calls #to_unsafe_h on ActionController::Parameters-like objects" do
      fake_params = double("ActionController::Parameters")
      allow(fake_params).to receive(:respond_to?).with(:to_unsafe_h).and_return(true)
      allow(fake_params).to receive(:to_unsafe_h).and_return({ "date" => "2024-01-01" })

      result = described_class.new(fake_params).tap { |v|
        v.instance_eval { required(:date).type(:date) }
      }.validate!

      expect(result[:date]).to eq(Date.new(2024, 1, 1))
    end
  end
end
