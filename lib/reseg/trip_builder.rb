# frozen_string_literal: true

module Reseg
  # Builds a list of trips from a list of segments:
  # - A trip is defined by at least one segment.
  # - Segments are sorted by their start time.
  # - A trip starts with a flight or train segment with origin in
  #   based_city, and might be closed with a flight or train segment with
  #   destination in based_city.
  class TripBuilder
    class BuildError < StandardError; end

    attr_reader :trips, :segments, :errors

    # Initializes a new TripBuilder object.
    #
    # @param segments [Array<Segment>] the segments to build the trips from.
    # @param context [Context] the context to use for the trips.
    def initialize(segments:, context:)
      @segments = segments.sort_by(&:starts_at)
      @trips = []
      @errors = []
      @context = context
      @based_city = context.based_city
    end

    # Builds the trips from the segments.
    #
    # @return [Boolean] true if all trips were built successfully,false otherwise.
    def build
      raise BuildError, "No flight/train segments found: cannot infer any trips" if moving_segments.empty?

      build_moving_segments
      validate_based_city!(moving_segments)

      build_hotel_segments

      @errors.empty?
    rescue BuildError => e
      @errors << e.message

      false
    end

    private

    def build_moving_segments
      current_trip = nil

      moving_segments.each do |segment|
        if current_trip.nil?
          current_trip = open_trip(segment)
        elsif end_segment?(segment)
          close_trip(current_trip, segment)
          current_trip = nil
        elsif flight_connection?(current_trip, segment)
          current_trip = add_flight_connection(current_trip, segment)
        elsif segment.origin_iata == current_trip.last_segment.destination_iata
          add_segment_to_trip(current_trip, segment)
        else
          @errors << "Segment at line #{segment.line_number} must start in #{@based_city} "\
          "or end in #{@based_city} or connect with the current trip"
        end
      end
    end

    def build_hotel_segments
      hotel_segments.each do |hotel|
        handle_hotel_segment(hotel)
      end
    end

    def hotel_segments
      @segments.select { |segment| segment.type == :hotel }
    end

    def moving_segments
      @segments.select { |segment| %i[flight train].include?(segment.type) }
    end

    def handle_hotel_segment(hotel)
      trip = @trips.find { |t| t.matches_hotel?(hotel) }

      if trip
        trip.insert_hotel_segment(hotel)
      else
        @errors << "Hotel at #{hotel.location_iata} (line #{hotel.line_number}) does not match any trip"
      end
    end

    def open_trip(segment)
      if segment.origin_iata == @based_city
        new_trip = Core::Trip.new(based_city: @based_city)
        @trips << new_trip
        new_trip.add_segment(segment)
        new_trip
      else
        @errors << "Segment at line #{segment.line_number} does not start at base city #{@based_city}"
        nil
      end
    end

    def close_trip(trip, segment)
      if trip.nil?
        @errors << "Segment at line #{segment.line_number} arrives at #{@based_city} but no trip is open"
      else
        # add last segment and close the trip
        trip.add_segment(segment)
        trip.close
      end
    end

    def add_flight_connection(trip, segment)
      segment.is_a_connection = true
      trip.add_segment(segment)
      trip.destination_iata = trip.last_segment.destination_iata

      next_segment = moving_segments[moving_segments.index(segment) + 1]

      return nil if next_segment.nil? || next_segment.origin_iata != segment.destination_iata

      trip
    end

    def add_segment_to_trip(trip, segment)
      trip.add_segment(segment)
      trip.destination_iata = trip.last_segment.destination_iata
    end

    def end_segment?(segment)
      segment.destination_iata == @based_city
    end

    def flight_connection?(trip, segment)
      return false if trip.last_segment.type == :hotel

      (trip.last_segment.starts_at + 24.hours > segment.starts_at &&
        trip.last_segment.destination_iata == segment.origin_iata) ||
        trip.last_segment.is_a_connection
    end

    def validate_based_city!(moving_segments)
      # based city matches the first segment origin
      return if moving_segments.first.origin_iata == @based_city

      # based city matches another segment origin
      if moving_segments.any? { |s| s.origin_iata == @based_city }
        msg = "Based city #{@based_city} does not match the first segment origin. "
        msg << "Continuing; this could lead to incorrect results."
        @errors << msg
        return
      end

      # no match found, try to guess the based city
      candidates = guess_base_candidates(moving_segments)
      msg = "Based city #{@based_city} does not match any segment origin."
      msg << "Possible base cities: #{candidates.join(", ")}" if candidates.any?
      raise BuildError, msg
    end

    def guess_base_candidates(segments)
      origins = segments.map(&:origin_iata)
      destinations = segments.map(&:destination_iata)

      # cities that appear as origin but not as destination
      (origins.uniq - destinations.uniq)
    end
  end
end
