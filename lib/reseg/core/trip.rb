# frozen_string_literal: true

module Reseg
  module Core
    # Represents a trip. A fresh object contains a list of empty segments,
    # and a based city.
    # - New segments can be inserted: flight/train and hotel.
    # - Inserting a hotel segment will validate that there is a moving segment
    #   with the same destination and dates as the hotel.
    # - Destination can be either set or inferred, and infer might return no
    #   candidate.
    # - The trip can be closed, meaning that it will ensure destination is set
    #   and no more segments can be inserted.
    class Trip
      class ValidationError < StandardError; end

      attr_reader :segments
      attr_accessor :destination_iata

      def initialize(based_city:)
        @based_city = based_city
        @segments = []
        @destination_iata = nil
        @closed = false
      end

      def close
        raise ValidationError, "Trip is already closed" if closed?
        raise ValidationError, "Trip must have at least one segment" if segments.empty?

        @destination_iata = infer_destination if @destination_iata.nil?

        raise ValidationError, "Destination IATA could not be inferred" if @destination_iata.nil?

        @closed = true
      end

      def add_segment(segment)
        raise ValidationError, "Trip is closed, cannot add segments." if closed?

        @segments << segment
      end

      # Insert a hotel segment into the trip after the last segment with
      # destination in the same city as the hotel.
      def insert_hotel_segment(hotel)
        last_segment = moving_segments.reverse.find do |segment|
          segment.destination_iata == hotel.location_iata
        end

        if last_segment.nil?
          raise ValidationError,
                "Hotel segment could not be inserted: no segment found with destination in #{hotel.location_iata}"
        end

        segments.insert(segments.index(last_segment) + 1, hotel)
      end

      def moving_segments
        segments.select { |segment| %i[flight train].include?(segment.type) }
      end

      def hotel_segments
        segments.select { |segment| segment.type == :hotel }
      end

      def matches_hotel?(hotel)
        @destination_iata == hotel.location_iata &&
          hotel.check_in_on.to_date  >= departure_date &&
          hotel.check_out_on.to_date <= arrival_date
      end

      def departure_date
        first_segment.starts_at.to_date
      end

      def arrival_date
        last_segment.ends_at.to_date
      end

      def first_segment
        segments.first
      end

      def last_segment
        segments.last
      end

      def last_flight_not_connection
        moving_segments.reject(&:is_a_connection).last
      end

      def closed?
        @closed
      end

      def duration
        return nil unless first_segment && last_segment

        last_segment.starts_at - first_segment.starts_at
      end

      private

      def format_date_time(date_time)
        date_time.strftime("%Y-%m-%d %H:%M")
      end

      def format_time(time)
        time.strftime("%H:%M")
      end

      def infer_destination
        return nil if moving_segments.empty?

        # Traverse backwards looking for the last segment that:
        # - is not a connection
        # - does not return to the base city
        moving_segments.reverse_each do |segment|
          next if segment.destination_iata == @based_city
          next if segment.is_a_connection

          return segment.destination_iata
        end
        # no segment found, ambiguous
        nil
      end
    end
  end
end
