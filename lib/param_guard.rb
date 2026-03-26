# frozen_string_literal: true

require_relative "param_guard/version"
require_relative "param_guard/validation_error"
require_relative "param_guard/field_validator"
require_relative "param_guard/validator"
require_relative "param_guard/mixin"

# ParamGuard — declarative parameter validation DSL for Ruby and Rails.
#
# @example Minimal usage
#   class MyService
#     include ParamGuard
#
#     def call(params)
#       cleaned = validate_params(params) do
#         required(:date).type(:date)
#         optional(:latitude).type(:float).range(-90.0..90.0)
#       end
#     end
#   end
module ParamGuard
  # Allow `include ParamGuard` (not just `include ParamGuard::Mixin`).
  def self.included(base)
    base.include(Mixin)
  end
end
