# frozen_string_literal: true

module Reseg
  module Core
    # Represents a hotel segment.
    # Hotel segments are defined by a start and end date, and an IATA code for
    # the location.
    class HotelSegment < Segment
      attr_reader :location_iata, :check_in_on, :check_out_on

      def initialize(location_iata:, check_in_on:, check_out_on:, line_number:)
        @location_iata = location_iata
        @check_in_on = check_in_on
        @check_out_on = check_out_on

        starts_at = to_time_at_start_of_day(check_in_on)
        ends_at = to_time_at_end_of_day(check_out_on)

        super(
          starts_at:,
          ends_at:,
          line_number: line_number
        )
      end

      def type
        :hotel
      end

      private

      def to_time_at_start_of_day(date)
        Time.new(date.year, date.month, date.day, 0, 0, 0)
      end

      def to_time_at_end_of_day(date)
        Time.new(date.year, date.month, date.day, 23, 59, 59)
      end
    end
  end
end
