# frozen_string_literal: true

module Reseg
  module Core
    # Abstract class for trip segments
    class Segment
      attr_reader :starts_at, :ends_at, :line_number
      attr_accessor :is_a_connection

      # Initializes a new Segment object.
      #
      # @param starts_at [Time] the start time of the segment.
      # @param ends_at [Time] the end time of the segment.
      # @param line_number [Integer] the line number of the segment.
      # @raise [ArgumentError] if the starts_at value is invalid.
      # @raise [ArgumentError] if the ends_at value is invalid.
      # @raise [ArgumentError] if the ends_at value is less than the starts_at value.
      def initialize(starts_at:, ends_at:, line_number:)
        @starts_at = validate_starts_at!(starts_at)
        @ends_at = validate_ends_at!(ends_at)
        @line_number = line_number
        @is_a_connection = false
      end

      def duration
        return nil unless starts_at && ends_at

        ends_at - starts_at
      end

      private

      def validate_starts_at!(value)
        raise ArgumentError, "starts_at must be a Time object" unless value.is_a?(Time)

        value
      end

      def validate_ends_at!(value)
        raise ArgumentError, "ends_at must be a Time object" unless value.is_a?(Time)
        raise ArgumentError, "ends_at must be >= starts_at" if starts_at && value < starts_at

        value
      end
    end
  end
end
