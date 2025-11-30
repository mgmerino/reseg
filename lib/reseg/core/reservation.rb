# frozen_string_literal: true

module Reseg
  module Core
    # Represents a reservation.
    # A reservation is defined by a start line number and a list of segments.
    class Reservation
      class ValidationError < StandardError; end

      attr_reader :segments, :start_line_number

      # Initializes a new Reservation object.
      #
      # @param segments [Array<Segment>] the segments of the reservation.
      # @param start_line_number [Integer] the line number of the reservation start.
      def initialize(start_line_number:)
        @start_line_number = start_line_number
        @segments = []
      end

      def add_segment(segment)
        @segments << segment
      end

      def validate!
        return unless segments.empty?

        raise ValidationError, "Reservation at line #{start_line_number} must have at least one segment"
      end
    end
  end
end
