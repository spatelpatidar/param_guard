# frozen_string_literal: true

module ParamGuard
  # Raised when one or more parameter validations fail.
  #
  # @example
  #   rescue ParamGuard::ValidationError => e
  #     e.message   # => "Validation failed: date is required, latitude must be in range -90..90"
  #     e.errors    # => { date: ["is required"], latitude: ["must be in range -90..90"] }
  class ValidationError < StandardError
    # @return [Hash{Symbol => Array<String>}] field-level error messages
    attr_reader :errors

    # @param errors [Hash{Symbol => Array<String>}]
    def initialize(errors)
      @errors = errors
      super(build_message)
    end

    private

    def build_message
      summaries = @errors.map do |field, messages|
        messages.map { |m| "#{field} #{m}" }.join(", ")
      end
      "Validation failed: #{summaries.join("; ")}"
    end
  end
end
