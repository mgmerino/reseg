# frozen_string_literal: true

module Reseg
  module Parsing
    # Represents line-based statements.
    # Statements are classified into two known types. All other lines are marked
    # as unknown:
    # - reservation_start: marks the start of a reservation block
    # - segment_line: holds segment information
    # - unknown: line with unknown or malformed format
    #
    # Only segment lines are expected to have a value.
    class Statement
      RESERVATION_START = :reservation_start
      SEGMENT_LINE = :segment_line
      UNKNOWN = :unknown

      TYPES = [RESERVATION_START, SEGMENT_LINE, UNKNOWN].freeze

      attr_reader :type, :value, :line_number, :raw

      # Initializes a new Statement object.
      #
      # @param type [Symbol] the type of the statement.
      # @param value [String] the value of the statement.
      # @param line_number [Integer] the line number of the statement.
      # @param raw [String] the raw line content.
      # @raise [ArgumentError] if the type is invalid.
      # @raise [ArgumentError] if the value is invalid for the type.
      def initialize(type:, value:, line_number:, raw:)
        @type = validate_type!(type)
        @value = validate_value!(value)
        @line_number = line_number
        @raw = raw
      end

      def reservation_start?
        type == RESERVATION_START
      end

      def segment_line?
        type == SEGMENT_LINE
      end

      def unknown?
        type == UNKNOWN
      end

      def to_s
        "#<Statement type=#{type.inspect} line_number=#{line_number} value=#{value.inspect}>"
      end

      private

      def validate_type!(type)
        return type if TYPES.include?(type)

        raise ArgumentError, "Invalid statement type: #{type.inspect}. "
      end

      # Validates value invariants per statement type.
      # Segment lines must always carry a value, while reservation start
      # not. This ensures consistency at the model level and protects the
      # parser from dealing with nil or unexpected values.
      def validate_value!(value)
        case type
        when RESERVATION_START
          unless valid_value_for_reservation_start?(value)
            raise ArgumentError, "Reservation start statements must not have a value (line #{line_number})"
          end
        when SEGMENT_LINE
          unless valid_value_for_segment_line?(value)
            raise ArgumentError, "Segment lines must have a non-empty value (line #{line_number})"
          end
        when UNKNOWN
          # no-op
        end

        value
      end

      def valid_value_for_segment_line?(value)
        value && !value.strip.empty?
      end

      def valid_value_for_reservation_start?(value)
        value.nil? || value.strip.empty?
      end
    end
  end
end
