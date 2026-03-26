# frozen_string_literal: true

module ParamGuard
  class Validator
    def initialize(params)
      @params     = normalize(params)
      @validators = []
    end

    def required(key)
      build_validator(key, required: true)
    end

    def optional(key)
      build_validator(key, required: false)
    end

    def validate!
      errors = collect_errors
      raise ValidationError, errors unless errors.empty?
      coerced_values
    end

    private

    def build_validator(key, required:)
      sym   = key.to_sym
      value = @params[sym]
      fv    = FieldValidator.new(sym, value: value, required: required)
      @validators << fv
      fv
    end

    def collect_errors
      @validators.each_with_object({}) do |fv, hash|
        hash[fv.field] = fv.errors unless fv.valid?
      end
    end

    def coerced_values
      @validators.each_with_object({}) do |fv, hash|
        # Omit absent optional fields — valid but no value to include
        next if fv.value.nil?
        hash[fv.field] = fv.value if fv.valid?
      end
    end

    def normalize(params)
      return {} if params.nil?
      hash = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
      hash.transform_keys(&:to_sym)
    end
  end
end
