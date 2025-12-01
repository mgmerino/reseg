# frozen_string_literal: true

module Reseg
  # Builds a reservation from a list of statements.
  class ReservationBuilder
    attr_reader :reservations, :segments, :errors

    # Initializes a new ReservationBuilder object.
    def initialize(statements:, context:, segment_parser: Parsing::SegmentParser)
      raise ArgumentError, "Statements must be an array" unless statements.is_a?(Array)

      @statements = statements
      @reservations = []
      @segments = []
      @current_reservation = nil
      @errors = []
      @context = context
      @segment_parser = segment_parser
    end

    def build
      return if @statements.empty?

      @statements.each do |statement|
        handle_statement(statement)
      end

      validate_reservation_segments
    end

    private

    def handle_statement(statement)
      if statement.reservation_start?
        @current_reservation = nil
        handle_reservation_start(statement)
      elsif statement.segment_line?
        handle_segment_line(statement)
      else
        handle_unknown(statement)
      end
    end

    def handle_reservation_start(statement)
      @current_reservation = Core::Reservation.new(start_line_number: statement.line_number)

      @reservations << @current_reservation
    end

    def handle_segment_line(statement)
      return unless ensure_current_reservation_exists(statement)

      segment = @segment_parser.new(
        segment_line: statement.value,
        line_number: statement.line_number,
        context: @context
      ).parse

      @current_reservation.add_segment(segment)
      @segments << segment
    rescue Parsing::SegmentParser::ParsingError => e
      @errors << e.message
    end

    def handle_unknown(statement)
      @errors << "Unknown statement at line #{statement.line_number}: #{statement.value}"
    end

    def ensure_current_reservation_exists(statement)
      return true unless @current_reservation.nil?

      @errors << "Segment line at line #{statement.line_number} must be part of a reservation"

      false
    end

    def validate_reservation_segments
      return if @reservations.empty?

      @reservations.each do |reservation|
        reservation.validate!
      rescue Core::Reservation::ValidationError => e
        @errors << e.message
      end
    end
  end
end
