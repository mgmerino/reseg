# frozen_string_literal: true

require "active_support"
require "active_support/time"
require "airports"

require_relative "reseg/version"
require_relative "reseg/context"
require_relative "reseg/reservation_builder"
require_relative "reseg/trip_builder"
require_relative "reseg/core/segment"
require_relative "reseg/core/flight_segment"
require_relative "reseg/core/hotel_segment"
require_relative "reseg/core/train_segment"
require_relative "reseg/core/reservation"
require_relative "reseg/core/trip"
require_relative "reseg/parsing/segment_parser"
require_relative "reseg/parsing/statement"
require_relative "reseg/parsing/scanner"

# Public API
module Reseg
  class Error < StandardError; end

  Result = Struct.new(:trips, :errors) do
    def success?
      errors.empty?
    end
  end

  def self.format(input, based_city:, time_zone: nil)
    result = parse(input, based_city:, time_zone:)

    return result.errors.join("\n") unless result.success?

    result.trips.map(&:to_s).join("\n")
  end

  def self.parse(input, based_city:, time_zone: nil)
    context = Context.new(based_city:, time_zone:)

    statements = []
    Parsing::Scanner.new(input).each { |st| statements << st }

    reservation_builder = ReservationBuilder.new(statements:, context:)
    reservation_builder.build

    segments = reservation_builder.segments
    trip_builder = TripBuilder.new(segments:, context:)
    trip_builder.build

    errors = reservation_builder.errors + trip_builder.errors

    Result.new(trip_builder.trips, errors)
  end
end
