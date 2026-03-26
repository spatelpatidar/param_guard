# frozen_string_literal: true

module ParamGuard
  # Represents the validation rules for a single parameter field.
  # Instances are chainable — each method returns +self+.
  #
  # @example
  #   FieldValidator.new(:latitude, value: "45.5", required: false)
  #     .type(:float)
  #     .range(-90.0..90.0)
  class FieldValidator
    SUPPORTED_TYPES = %i[string integer float date boolean].freeze

    # @return [Symbol] the field name
    attr_reader :field

    # @return [Array<String>] accumulated error messages for this field
    attr_reader :errors

    # @param field   [Symbol] parameter key
    # @param value   [Object] raw value from params (may be nil/absent)
    # @param required [Boolean] whether the field must be present
    def initialize(field, value:, required:)
      @field    = field
      @raw      = value
      @required = required
      @errors   = []
      @coerced  = nil          # set after successful .type() coercion
      @typed    = false        # guards against chaining .range without .type

      check_presence
    end

    # --- Chainable validation rules -------------------------------------------

    # Coerce and validate the parameter's type.
    #
    # @param kind [Symbol] one of :string, :integer, :float, :date, :boolean
    # @return [self]
    def type(kind)
      unless SUPPORTED_TYPES.include?(kind)
        raise ArgumentError, "Unsupported type :#{kind}. Supported: #{SUPPORTED_TYPES.map { |t| ":#{t}" }.join(", ")}"
      end

      return self if skip?   # already invalid / absent — skip further checks

      result = coerce(@raw, kind)
      if result.success?
        @coerced = result.value
        @typed   = true
      else
        @errors << result.message
      end

      self
    end

    # Validate that the (coerced) value falls within a Range.
    #
    # @param bounds [Range] e.g. -90..90 or 1..100
    # @return [self]
    def range(bounds)
      raise ArgumentError, "range() requires a Range argument" unless bounds.is_a?(Range)

      return self if skip?

      comparable = @typed ? @coerced : @raw
      unless bounds.cover?(comparable)
        @errors << "must be in range #{bounds}"
      end

      self
    end

    # Validate that the value is one of an allowed set.
    #
    # @param allowed [Array] list of accepted values
    # @return [self]
    def inclusion(allowed)
      raise ArgumentError, "inclusion() requires an Array argument" unless allowed.is_a?(Array)

      return self if skip?

      comparable = @typed ? @coerced : @raw
      unless allowed.include?(comparable)
        formatted = allowed.map(&:inspect).join(", ")
        @errors << "must be one of [#{formatted}]"
      end

      self
    end

    # @return [Boolean] true when this field has no errors
    def valid?
      @errors.empty?
    end

    # @return [Object, nil] the coerced value, or nil if absent/invalid
    def value
      @coerced.nil? ? @raw : @coerced
    end

    private

    # True when we should skip further checks (field absent or already errored)
    def skip?
      absent? || @errors.any?
    end

    def absent?
      @raw.nil? || ((@raw.is_a?(String)) && @raw.strip.empty?)
    end

    def check_presence
      @errors << "is required" if @required && absent?
    end

    # --- Type coercion --------------------------------------------------------

    CoercionResult = Struct.new(:success?, :value, :message)

    def coerce(raw, kind)
      case kind
      when :string
        CoercionResult.new(true, raw.to_s, nil)

      when :integer
        coerce_integer(raw)

      when :float
        coerce_float(raw)

      when :date
        coerce_date(raw)

      when :boolean
        coerce_boolean(raw)
      end
    end

    def coerce_integer(raw)
      value = Integer(raw)
      CoercionResult.new(true, value, nil)
    rescue ArgumentError, TypeError
      CoercionResult.new(false, nil, "must be an integer")
    end

    def coerce_float(raw)
      value = Float(raw)
      CoercionResult.new(true, value, nil)
    rescue ArgumentError, TypeError
      CoercionResult.new(false, nil, "must be a float")
    end

    def coerce_date(raw)
      require "date"
      value = raw.is_a?(::Date) ? raw : ::Date.parse(raw.to_s)
      CoercionResult.new(true, value, nil)
    rescue ArgumentError, TypeError
      CoercionResult.new(false, nil, "must be a valid date (YYYY-MM-DD)")
    end

    def coerce_boolean(raw)
      truthy = [true,  "true",  "1", "yes", 1]
      falsy  = [false, "false", "0", "no",  0]

      # Use explicit string/value comparison — Array#include? uses ==,
      # and in Ruby "false" == false is always false, so we normalize first.
      normalized = raw.is_a?(String) ? raw.downcase.strip : raw

      if truthy.include?(normalized)
        CoercionResult.new(true, true, nil)
      elsif falsy.include?(normalized)
        CoercionResult.new(true, false, nil)
      else
        CoercionResult.new(false, nil, "must be a boolean (true/false)")
      end
    end
  end
end
