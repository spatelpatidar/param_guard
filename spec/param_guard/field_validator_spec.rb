# frozen_string_literal: true

require "spec_helper"

RSpec.describe ParamGuard::FieldValidator do
  # --- Presence -----------------------------------------------------------

  describe "presence" do
    context "when required and value is nil" do
      subject { described_class.new(:age, value: nil, required: true) }

      it "is invalid" do
        expect(subject).not_to be_valid
      end

      it "reports 'is required'" do
        expect(subject.errors).to include("is required")
      end
    end

    context "when required and value is empty string" do
      subject { described_class.new(:age, value: "  ", required: true) }

      it "is invalid" do
        expect(subject).not_to be_valid
      end
    end

    context "when optional and value is nil" do
      subject { described_class.new(:age, value: nil, required: false) }

      it "is valid" do
        expect(subject).to be_valid
      end
    end
  end

  # --- Type: integer ------------------------------------------------------

  describe "#type(:integer)" do
    it "coerces a string integer" do
      fv = described_class.new(:count, value: "42", required: true).type(:integer)
      expect(fv).to be_valid
      expect(fv.value).to eq(42)
    end

    it "accepts a native integer" do
      fv = described_class.new(:count, value: 7, required: true).type(:integer)
      expect(fv).to be_valid
      expect(fv.value).to eq(7)
    end

    it "fails on a non-numeric string" do
      fv = described_class.new(:count, value: "abc", required: true).type(:integer)
      expect(fv).not_to be_valid
      expect(fv.errors).to include("must be an integer")
    end
  end

  # --- Type: float --------------------------------------------------------

  describe "#type(:float)" do
    it "coerces a string float" do
      fv = described_class.new(:lat, value: "45.5", required: true).type(:float)
      expect(fv).to be_valid
      expect(fv.value).to eq(45.5)
    end

    it "coerces a string integer to float" do
      fv = described_class.new(:lat, value: "10", required: true).type(:float)
      expect(fv).to be_valid
      expect(fv.value).to eq(10.0)
    end

    it "fails on a non-numeric string" do
      fv = described_class.new(:lat, value: "bad", required: true).type(:float)
      expect(fv).not_to be_valid
      expect(fv.errors).to include("must be a float")
    end
  end

  # --- Type: date ---------------------------------------------------------

  describe "#type(:date)" do
    it "coerces a valid date string" do
      fv = described_class.new(:date, value: "2024-06-15", required: true).type(:date)
      expect(fv).to be_valid
      expect(fv.value).to eq(Date.new(2024, 6, 15))
    end

    it "accepts a Date object directly" do
      date = Date.today
      fv = described_class.new(:date, value: date, required: true).type(:date)
      expect(fv).to be_valid
      expect(fv.value).to eq(date)
    end

    it "fails on an invalid date string" do
      fv = described_class.new(:date, value: "not-a-date", required: true).type(:date)
      expect(fv).not_to be_valid
      expect(fv.errors).to include("must be a valid date (YYYY-MM-DD)")
    end
  end

  # --- Type: boolean ------------------------------------------------------

  describe "#type(:boolean)" do
    %w[true 1 yes].each do |truthy|
      it "coerces '#{truthy}' to true" do
        fv = described_class.new(:active, value: truthy, required: true).type(:boolean)
        expect(fv).to be_valid
        expect(fv.value).to eq(true)
      end
    end

    %w[false 0 no].each do |falsy|
      it "coerces '#{falsy}' to false" do
        fv = described_class.new(:active, value: falsy, required: true).type(:boolean)
        expect(fv).to be_valid
        expect(fv.value).to eq(false)
      end
    end

    it "fails on an unrecognised boolean value" do
      fv = described_class.new(:active, value: "maybe", required: true).type(:boolean)
      expect(fv).not_to be_valid
    end
  end

  # --- Type: string -------------------------------------------------------

  describe "#type(:string)" do
    it "accepts any string-able value" do
      fv = described_class.new(:name, value: "hello", required: true).type(:string)
      expect(fv).to be_valid
      expect(fv.value).to eq("hello")
    end
  end

  # --- Range --------------------------------------------------------------

  describe "#range" do
    it "passes when float is within range" do
      fv = described_class.new(:lat, value: "45.0", required: true)
               .type(:float).range(-90.0..90.0)
      expect(fv).to be_valid
    end

    it "fails when float is out of range" do
      fv = described_class.new(:lat, value: "200.0", required: true)
               .type(:float).range(-90.0..90.0)
      expect(fv).not_to be_valid
      expect(fv.errors).to include("must be in range -90.0..90.0")
    end

    it "passes when integer is within range" do
      fv = described_class.new(:guests, value: "5", required: true)
               .type(:integer).range(1..20)
      expect(fv).to be_valid
    end

    it "raises ArgumentError when argument is not a Range" do
      expect {
        described_class.new(:n, value: "5", required: true).range("bad")
      }.to raise_error(ArgumentError, /Range/)
    end
  end

  # --- Inclusion ----------------------------------------------------------

  describe "#inclusion" do
    it "passes when value is in allowed list" do
      fv = described_class.new(:status, value: "confirmed", required: true)
               .inclusion(%w[pending confirmed cancelled])
      expect(fv).to be_valid
    end

    it "fails when value is not in allowed list" do
      fv = described_class.new(:status, value: "unknown", required: true)
               .inclusion(%w[pending confirmed cancelled])
      expect(fv).not_to be_valid
      expect(fv.errors.first).to match(/must be one of/)
    end

    it "works after type coercion" do
      fv = described_class.new(:priority, value: "2", required: true)
               .type(:integer).inclusion([1, 2, 3])
      expect(fv).to be_valid
    end

    it "raises ArgumentError when argument is not an Array" do
      expect {
        described_class.new(:n, value: "x", required: true).inclusion("bad")
      }.to raise_error(ArgumentError, /Array/)
    end
  end

  # --- Chaining skips on prior error -------------------------------------

  describe "chaining skips after earlier failure" do
    it "does not add range error when type failed" do
      fv = described_class.new(:lat, value: "not-a-float", required: true)
               .type(:float).range(-90.0..90.0)
      expect(fv.errors.length).to eq(1)
      expect(fv.errors.first).to include("must be a float")
    end

    it "does not add inclusion error when required check failed" do
      fv = described_class.new(:status, value: nil, required: true)
               .inclusion(%w[a b c])
      expect(fv.errors.length).to eq(1)
      expect(fv.errors.first).to include("is required")
    end
  end

  # --- Unsupported type ---------------------------------------------------

  describe "unsupported type" do
    it "raises ArgumentError" do
      expect {
        described_class.new(:x, value: "foo", required: true).type(:xml)
      }.to raise_error(ArgumentError, /Unsupported type/)
    end
  end
end
