# frozen_string_literal: true

require "spec_helper"

RSpec.describe ParamGuard::ValidationError do
  let(:errors) do
    { date: ["is required"], latitude: ["must be a float", "must be in range -90.0..90.0"] }
  end

  subject { described_class.new(errors) }

  it "is a StandardError" do
    expect(subject).to be_a(StandardError)
  end

  it "exposes #errors" do
    expect(subject.errors).to eq(errors)
  end

  it "builds a human-readable message" do
    expect(subject.message).to start_with("Validation failed:")
    expect(subject.message).to include("date is required")
    expect(subject.message).to include("latitude must be a float")
  end
end
