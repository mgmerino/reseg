# frozen_string_literal: true

module Reseg
  module Parsing
    # Parses segment lines into flight, train, or hotel segments:
    # - `Flight <IATA_CODE> <ISO_EXTENDED_DATE> <HH:MM> -> <IATA_CODE> <HH:MM>`
    # - `Train <IATA_CODE> <ISO_EXTENDED_DATE> <HH:MM> -> <IATA_CODE> <HH:MM>`
    # - `Hotel <IATA_CODE> <ISO_EXTENDED_DATE> -> <ISO_EXTENDED_DATE>`
    class SegmentParser
      class ParsingError < StandardError; end

      FLIGHT_REGEX = /\AFlight (\w{3}) (\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}) -> (\w{3}) (\d{2}:\d{2})\z/i
      TRAIN_REGEX = /\ATrain (\w{3}) (\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}) -> (\w{3}) (\d{2}:\d{2})\z/i
      HOTEL_REGEX = /\AHotel (\w{3}) (\d{4}-\d{2}-\d{2}) -> (\d{4}-\d{2}-\d{2})\z/i

      # Initializes a new SegmentParser object.
      #
      # @param segment_line [String] the segment line to parse.
      # @param line_number [Integer] the line number of the segment.
      # @param context [Context] the context to use for the parsing.
      def initialize(segment_line:, line_number:, context:)
        @segment_line = segment_line
        @line_number = line_number
        @context = context
      end

      def parse
        case @segment_line
        when /\AFlight\b/
          parse_flight_segment
        when /\ATrain\b/
          parse_train_segment
        when /\AHotel\b/
          parse_hotel_segment
        else
          raise ParsingError, "Unknown segment type at line #{@line_number}: #{@segment_line.inspect}"
        end
      rescue Core::Segment::ValidationError => e
        raise ParsingError, "Invalid segment line #{@line_number}: #{e.message}"
      end

      private

      def parse_flight_segment
        match = @segment_line.match(FLIGHT_REGEX)
        raise ParsingError, "Invalid flight segment line #{@line_number}: #{@segment_line.inspect}" unless match

        origin_iata, date_str, dep_time_str, destination_iata, arr_time_str = match.captures

        Core::FlightSegment.new(
          origin_iata:,
          destination_iata:,
          departure_at: parse_date_time(date_str, dep_time_str),
          arrival_at: parse_date_time(date_str, arr_time_str),
          line_number: @line_number
        )
      end

      def parse_train_segment
        match = @segment_line.match(TRAIN_REGEX)
        raise ParsingError, "Invalid train segment line #{@line_number}: #{@segment_line.inspect}" unless match

        origin_iata, date_str, dep_time_str, destination_iata, arr_time_str = match.captures

        Core::TrainSegment.new(
          origin_iata:,
          destination_iata:,
          departure_at: parse_date_time(date_str, dep_time_str),
          arrival_at: parse_date_time(date_str, arr_time_str),
          line_number: @line_number
        )
      end

      def parse_hotel_segment
        match = @segment_line.match(HOTEL_REGEX)
        raise ParsingError, "Invalid hotel segment line #{@line_number}: #{@segment_line.inspect}" unless match

        location_iata, check_in_on, check_out_on = match.captures

        Core::HotelSegment.new(
          location_iata:,
          check_in_on: parse_date(check_in_on),
          check_out_on: parse_date(check_out_on),
          line_number: @line_number
        )
      end

      def parse_date_time(date_str, time_str)
        time_zone.strptime("#{date_str} #{time_str}", "%Y-%m-%d %H:%M")
      end

      def parse_date(date_str)
        time_zone.strptime(date_str, "%Y-%m-%d").to_date
      end

      def time_zone
        ActiveSupport::TimeZone.new(@context.time_zone)
      end
    end
  end
end
