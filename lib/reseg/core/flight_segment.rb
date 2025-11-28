# frozen_string_literal: true

module Reseg
  module Core
    # Represents a flight segment.
    # Flight segments are defined by a start and end time, and an IATA codes
    # both for the origin and destination.
    class FlightSegment < Segment
      attr_reader :origin_iata, :destination_iata, :is_a_connection, :departure_at, :arrival_at

      def initialize(origin_iata:, destination_iata:, departure_at:, arrival_at:, line_number:)
        @origin_iata = origin_iata
        @destination_iata = destination_iata
        @departure_at = departure_at
        @arrival_at = arrival_at

        super(
          starts_at: departure_at,
          ends_at: arrival_at,
          line_number: line_number
        )
      end

      def type
        :flight
      end
    end
  end
end
