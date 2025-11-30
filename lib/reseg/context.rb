# frozen_string_literal: true

module Reseg
  # Represents a context for the formatter.
  # The context includes the based city and the time zone.
  # The time zone is injected when parsing dates and times.
  # The based city is injected in the trip builder to infer trip structure.
  class Context
    DEFAULT_TIME_ZONE = "UTC"

    attr_reader :based_city, :time_zone

    # Initializes a new Context object.
    #
    # @param based_city [String] the based city.
    # @param time_zone [String] the time zone. Overrides the time zone inferred from the based city.
    # @param location_resolver [Class] the location resolver.
    # @raise [ArgumentError] if the based city is not a 3 letter string.
    # @raise [ArgumentError] if the based city is not a valid IATA code.
    def initialize(based_city:, time_zone: nil, location_resolver: Airports)
      @location_resolver = location_resolver
      @based_city = validate_based_city!(based_city)

      @time_zone = validate_time_zone!(time_zone) || infer_time_zone_from_based_city || default_time_zone
    end

    private

    attr_reader :location_resolver

    def validate_based_city!(based_city)
      unless based_city.is_a?(String) && based_city.length == 3
        raise ArgumentError,
              "Based city must be a 3 letter string"
      end

      return based_city if @location_resolver.nil? # location resolver is not required

      unless location_resolver.find_by_iata_code(based_city)
        raise ArgumentError,
              "Based city must be a valid IATA code"
      end

      based_city
    end

    def validate_time_zone!(time_zone)
      return if time_zone.nil?

      unless time_zone.is_a?(String)
        raise ArgumentError,
              "Time zone must be a string"
      end

      unless ActiveSupport::TimeZone.new(time_zone)
        raise ArgumentError,
              "Time zone must be a valid time zone"
      end

      time_zone
    end

    def infer_time_zone_from_based_city
      location&.tz_name
    end

    def location
      @location ||= location_resolver&.find_by_iata_code(@based_city)
    end

    def default_time_zone
      DEFAULT_TIME_ZONE
    end
  end
end
