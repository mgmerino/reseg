# frozen_string_literal: true

module Reseg
  RSpec.describe ReservationBuilder do
    let(:context) { instance_double(Context, based_city: "MAD") }
    let(:segment) { instance_double(Core::Segment) }
    let(:segment_parser_class) do
      class_double(Parsing::SegmentParser)
    end
    let(:reservation_builder) do
      described_class.new(statements: statements, context: context, segment_parser: segment_parser_class)
    end

    describe "#initialize" do
      context "when the statements are not an array" do
        let(:statements) { "not an array" }

        it "raises an error" do
          expect { reservation_builder }.to raise_error(ArgumentError)
        end
      end
    end

    describe "#build" do
      let(:parser_double) do
        instance_double(Parsing::SegmentParser, parse: segment)
      end

      before do
        allow(segment_parser_class).to receive(:new)
          .and_return(parser_double)
      end

      context "when the statements are valid" do
        let(:statements) do
          [Parsing::Statement.new(type: Parsing::Statement::RESERVATION_START, value: nil, line_number: 1, raw: "START"),
           Parsing::Statement.new(type: Parsing::Statement::SEGMENT_LINE, value: "Segment 1", line_number: 2,
                                  raw: "Segment 1"),
           Parsing::Statement.new(type: Parsing::Statement::SEGMENT_LINE, value: "Segment 2", line_number: 3,
                                  raw: "Segment 2")]
        end

        it "builds reservations and segments from statements" do
          reservation_builder.build

          expect(reservation_builder.reservations.size).to eq(1)
          expect(reservation_builder.reservations.first).to be_a(Core::Reservation)

          expect(reservation_builder.segments.size).to eq(2)
          expect(reservation_builder.segments).to all(eq(segment))
        end
      end

      context "when the reservation start statement is missing" do
        let(:statements) do
          [Parsing::Statement.new(type: Parsing::Statement::SEGMENT_LINE, value: "Segment 1", line_number: 1,
                                  raw: "Segment 1")]
        end

        it "does not parse the segment line and logs the error" do
          reservation_builder.build

          expect(reservation_builder.reservations).to be_empty
          expect(reservation_builder.segments).to be_empty
          expect(reservation_builder.errors).to include("Segment line at line 1 must be part of a reservation")
        end
      end

      context "when the reservation does not contain any segments" do
        let(:statements) do
          [Parsing::Statement.new(type: Parsing::Statement::RESERVATION_START, value: nil, line_number: 1,
                                  raw: "START")]
        end

        it "parses the reservation start and logs the error" do
          reservation_builder.build

          expect(reservation_builder.segments).to be_empty
          expect(reservation_builder.errors).to include("Reservation at line 1 must have at least one segment")
        end
      end

      context "when the segment parser raises an error" do
        before do
          allow(segment_parser_class).to receive(:new)
            .and_return(parser_double)

          allow(parser_double).to receive(:parse)
            .and_raise(Parsing::SegmentParser::ParsingError.new("Parsing error"))
        end

        let(:statements) do
          [
            Parsing::Statement.new(type: Parsing::Statement::RESERVATION_START, value: nil, line_number: 1,
                                   raw: "START"),
            Parsing::Statement.new(type: Parsing::Statement::SEGMENT_LINE,
                                   value: "Invalid segment line",
                                   line_number: 1,
                                   raw: "Invalid segment line")
          ]
        end

        it "does not parse the segment line and logs the error" do
          reservation_builder.build

          expect(reservation_builder.segments).to be_empty
          expect(reservation_builder.errors).to include("Parsing error")
        end
      end
    end
  end
end
