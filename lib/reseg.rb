# frozen_string_literal: true

require "active_support"
require "active_support/time"

require_relative "reseg/version"
require_relative "reseg/core/segment"
require_relative "reseg/parsing/statement"
require_relative "reseg/parsing/scanner"

module Reseg
  class Error < StandardError; end
  # Your code goes here...
end
