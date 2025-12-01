# frozen_string_literal: true

require "active_support"
require "active_support/time"
require "airports"

require_relative "reseg/version"
require_relative "reseg/context"
require_relative "reseg/reservation_builder"
require_relative "reseg/core/segment"
require_relative "reseg/core/flight_segment"
require_relative "reseg/core/hotel_segment"
require_relative "reseg/core/train_segment"
require_relative "reseg/core/reservation"
require_relative "reseg/parsing/segment_parser"
require_relative "reseg/parsing/statement"
require_relative "reseg/parsing/scanner"

module Reseg
  class Error < StandardError; end
  # Your code goes here...
end
