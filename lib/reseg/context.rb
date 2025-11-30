# frozen_string_literal: true

module Reseg
  # Represents a timezone and city context.
  class Context
    attr_reader :based_city, :time_zone

    def initialize(based_city:, time_zone: nil, location_resolver: nil)
      @based_city = based_city
      @location_resolver = location_resolver

      @time_zone = time_zone || infer_time_zone_from_based_city || default_time_zone
    end

    private

    attr_reader :location_resolver

    def infer_time_zone_from_based_city
      return nil unless location_resolver

      location = location_resolver.call(based_city)
      location&.time_zone
    end

    def default_time_zone
      "UTC"
    end
  end
end
