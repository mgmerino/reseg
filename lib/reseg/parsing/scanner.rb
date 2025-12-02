# frozen_string_literal: true

# Scans the input and yields statements.
module Reseg
  module Parsing
    # Scans the input and yields statements.
    class Scanner
      include Enumerable

      RESERVATION_START_PATTERN = /\ARESERVATION\z/i
      SEGMENT_PATTERN = /\ASEGMENT:/i

      # Initializes a new Scanner object.
      #
      # @param input [IO, StringIO, String] the input to scan.
      # @raise [ArgumentError] if the input is not supported.
      def initialize(input)
        @input = normalize_input(input)
      end

      # Yields statements from the input. For testing convenience, accepts a
      # block or returns an Enumerator. The input is normalized to a StringIO if
      # it is not already, so it is easily iterable.
      #
      # @return [Enumerator] if no block is given.
      # @raise [ArgumentError] if the input is not supported.
      # @yield [Statement] the statement object.
      def each
        return enum_for(:each) unless block_given?

        line_number = 0
        @input.each_line do |raw_line|
          line_number += 1
          line_content = raw_line.strip

          next if line_content.empty?

          yield processed_line(line_content, line_number, raw_line)
        end
      end

      private

      def normalize_input(input)
        case input
        when IO, StringIO
          input
        when String
          StringIO.new(input)
        else
          raise ArgumentError, "Input type not supported: #{input.class}"
        end
      end

      def processed_line(line_content, line_number, raw_line)
        case line_content
        when RESERVATION_START_PATTERN
          Statement.new(type: Statement::RESERVATION_START, value: nil, line_number:, raw: raw_line)
        when SEGMENT_PATTERN
          if (match = line_content.match(/\ASEGMENT:\s+(.+)/i))
            value = match[1]
            Statement.new(type: Statement::SEGMENT_LINE, value:, line_number:, raw: raw_line)
          else
            Statement.new(type: Statement::UNKNOWN, value: line_content, line_number:, raw: raw_line)
          end
        else
          Statement.new(type: Statement::UNKNOWN, value: line_content, line_number:, raw: raw_line)
        end
      end
    end
  end
end
