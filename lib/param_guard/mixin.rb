# frozen_string_literal: true

module ParamGuard
  # Include this module in any class (Rails controller, service object, etc.)
  # to gain the +validate_params+ DSL method.
  #
  # @example Rails controller
  #   class BookingsController < ApplicationController
  #     include ParamGuard
  #
  #     def create
  #       cleaned = validate_params(params) do
  #         required(:date).type(:date)
  #         optional(:latitude).type(:float).range(-90.0..90.0)
  #         optional(:longitude).type(:float).range(-180.0..180.0)
  #         optional(:guests).type(:integer).range(1..20)
  #         optional(:status).inclusion(["pending", "confirmed", "cancelled"])
  #       end
  #       # cleaned => { date: #<Date>, latitude: 45.5, ... }
  #     rescue ParamGuard::ValidationError => e
  #       render json: { errors: e.errors }, status: :unprocessable_entity
  #     end
  #   end
  #
  # @example Service object
  #   class ReservationService
  #     include ParamGuard
  #
  #     def call(params)
  #       cleaned = validate_params(params) do
  #         required(:date).type(:date)
  #         required(:user_id).type(:integer)
  #       end
  #       # ... business logic with cleaned params
  #     end
  #   end
  module Mixin
    # Evaluate a validation block against the given params.
    #
    # @param params [Hash, ActionController::Parameters]
    # @yield DSL block — calls to +required+ and +optional+
    # @return [Hash{Symbol => Object}] coerced values for all valid fields
    # @raise [ParamGuard::ValidationError] on any validation failure
    def validate_params(params, &block)
      validator = Validator.new(params)
      validator.instance_eval(&block)
      validator.validate!
    end
  end
end
