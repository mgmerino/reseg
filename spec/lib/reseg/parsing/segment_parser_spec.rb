# frozen_string_literal: true

module Reseg
  module Parsing
    RSpec.describe SegmentParser do
      let(:line_number) { 1 }
      let(:based_city_iata) { "MAD" }
      let(:destination_iata) { "LHR" }
      let(:context) { Context.new(based_city: based_city_iata) }
      let(:segment_parser) do
        described_class.new(segment_line: segment_line, line_number: line_number, context: context)
      end

      describe "#parse" do
        context "when the segment line is invalid" do
          let(:segment_line) { "Train #{based_city_iata} 2026-01-01 10:00 -> #{destination_iata} 12:00 invalid" }

          it "raises an error" do
            expect { segment_parser.parse }.to raise_error(SegmentParser::ParsingError)
          end
        end

        context "when the segment line contains invalid dates" do
          let(:invalid_date) { "2026-13-01" }
          let(:segment_line) { "Flight #{based_city_iata} #{invalid_date} 10:00 -> #{destination_iata} 12:00" }

          it "raises an error" do
            expect { segment_parser.parse }.to raise_error(ArgumentError)
          end
        end

        context "when the segment line contains invalid times" do
          let(:invalid_time) { "10:00:00" }
          let(:segment_line) { "Train #{based_city_iata} 2026-01-01 #{invalid_time} -> #{destination_iata} 12:00:00" }

          it "raises an error" do
            expect { segment_parser.parse }.to raise_error(SegmentParser::ParsingError)
          end
        end

        context "when the segment line contains invalid IATA codes" do
          let(:invalid_iata) { "MADRID" }
          let(:segment_line) { "Flight #{invalid_iata} 2026-01-01 10:00 -> #{destination_iata} 12:00" }

          it "raises an error" do
            expect { segment_parser.parse }.to raise_error(SegmentParser::ParsingError)
          end
        end

        context "when the segment line contains invalid segment type" do
          let(:invalid_type) { "not-valid" }
          let(:segment_line) { "#{invalid_type} #{based_city_iata} 2026-01-01 10:00 -> #{destination_iata} 12:00" }

          it "raises an error" do
            expect { segment_parser.parse }.to raise_error(SegmentParser::ParsingError)
          end
        end

        context "when the time zone is set in the context" do
          let(:segment_line) { "Flight #{based_city_iata} 2026-01-01 10:00 -> #{destination_iata} 12:00" }
          let(:context) { Context.new(based_city: based_city_iata, time_zone: "Europe/London") }

          it "returns a segment with the dates parsed in the expected time zone" do
            expect(segment_parser.parse.departure_at.zone).to eq("GMT")
            expect(segment_parser.parse.arrival_at.zone).to eq("GMT")
          end
        end

        context "when the segment line is a flight segment" do
          let(:segment_line) { "Flight #{based_city_iata} 2026-01-01 10:00 -> #{destination_iata} 12:00" }

          it "parses a flight segment" do
            expect(segment_parser.parse).to be_a(Core::FlightSegment)
          end

          it "returns a flight segment with expected attributes" do
            expect(segment_parser.parse).to have_attributes(
              origin_iata: "MAD",
              destination_iata: "LHR",
              departure_at: Time.new(2026, 1, 1, 10, 0, 0, "+01:00"),
              arrival_at: Time.new(2026, 1, 1, 12, 0, 0, "+01:00"),
              line_number: 1
            )
          end
        end

        context "when the segment line is a train segment" do
          let(:segment_line) { "Train #{based_city_iata} 2026-01-01 10:00 -> #{destination_iata} 12:00" }

          it "parses a train segment" do
            expect(segment_parser.parse).to be_a(Core::TrainSegment)
          end

          it "returns a train segment with expected attributes" do
            expect(segment_parser.parse).to have_attributes(
              origin_iata: "MAD",
              destination_iata: "LHR",
              departure_at: Time.new(2026, 1, 1, 10, 0, 0, "+01:00"),
              arrival_at: Time.new(2026, 1, 1, 12, 0, 0, "+01:00"),
              line_number: 1
            )
          end
        end

        context "when the segment line is a hotel segment" do
          let(:segment_line) { "Hotel BCN 2026-01-01 -> 2026-01-02" }

          it "parses a hotel segment" do
            expect(segment_parser.parse).to be_a(Core::HotelSegment)
          end

          it "returns a hotel segment with expected attributes" do
            expect(segment_parser.parse).to have_attributes(
              location_iata: "BCN",
              check_in_on: Date.new(2026, 1, 1),
              check_out_on: Date.new(2026, 1, 2),
              line_number: 1
            )
          end
        end
      end
    end
  end
end
