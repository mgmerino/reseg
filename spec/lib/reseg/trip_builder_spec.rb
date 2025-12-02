# frozen_string_literal: true

module Reseg
  RSpec.describe TripBuilder do
    let(:based_city) { "MAD" }
    let(:segment1) do
      Core::FlightSegment.new(origin_iata: "MAD",
                              destination_iata: "BCN",
                              departure_at: Time.parse("2026-01-01 10:00:00 +01:00"),
                              arrival_at: Time.parse("2026-01-01 11:00:00 +01:00"),
                              line_number: 1)
    end
    let(:segment2) do
      Core::FlightSegment.new(origin_iata: "BCN",
                              destination_iata: "AMS",
                              departure_at: Time.parse("2026-01-01 12:00:00 +01:00"),
                              arrival_at: Time.parse("2026-01-01 14:45:00 +01:00"),
                              line_number: 2)
    end
    let(:segment3) do
      Core::FlightSegment.new(origin_iata: "AMS",
                              destination_iata: "MAD",
                              departure_at: Time.parse("2026-01-03 12:00:00 +01:00"),
                              arrival_at: Time.parse("2026-01-03 15:00:00 +01:00"),
                              line_number: 3)
    end
    let(:segment4) do
      Core::FlightSegment.new(origin_iata: "MAD",
                              destination_iata: "BCN",
                              departure_at: Time.parse("2026-02-03 10:00:00 +01:00"),
                              arrival_at: Time.parse("2026-02-03 11:00:00 +01:00"),
                              line_number: 4)
    end
    let(:segment5) do
      Core::FlightSegment.new(origin_iata: "BCN",
                              destination_iata: "MAD",
                              departure_at: Time.parse("2026-02-05 12:00:00 +01:00"),
                              arrival_at: Time.parse("2026-02-05 14:45:00 +01:00"),
                              line_number: 5)
    end
    let(:hotel1) do
      Core::HotelSegment.new(location_iata: "AMS",
                             check_in_on: Time.parse("2026-01-01 10:00:00 +01:00"),
                             check_out_on: Time.parse("2026-01-03 12:00:00 +01:00"),
                             line_number: 4)
    end
    let(:hotel2) do
      Core::HotelSegment.new(location_iata: "BCN",
                             check_in_on: Time.parse("2026-02-03 15:00:00 +01:00"),
                             check_out_on: Time.parse("2026-02-05 10:00:00 +01:00"),
                             line_number: 5)
    end
    let(:segments) { [hotel1, segment3, segment2, segment1, segment4, segment5, hotel2] }
    let(:context) { instance_double(Context, based_city:) }
    let(:trip_builder) { described_class.new(segments: segments, context: context) }

    describe "#initialize" do
      it "initializes a trip builder object" do
        expect(trip_builder).to be_a(described_class)
      end

      it "sorts the segments by starts_at" do
        expect(trip_builder.segments)
          .to eq([hotel1, segment1, segment2, segment3, hotel2, segment4, segment5])
      end
    end

    describe "#build" do
      it "returns true if all trips were built successfully" do
        expect(trip_builder.build).to be(true)
      end

      it "builds expected trips" do
        trip_builder.build

        expect(trip_builder.trips.size).to eq(2)
      end

      it "places the hotel segments after the last flight segment" do
        trip_builder.build

        expect(trip_builder.trips.first.segments)
          .to eq([segment1, segment2, hotel1, segment3])
        expect(trip_builder.trips.last.segments)
          .to eq([segment4, hotel2, segment5])
      end

      it "marks the expected segments as connections" do
        trip_builder.build

        expect(segment2.is_a_connection).to be(true)
      end

      context "when the gap between flights is exactly 24 hours" do
        let(:segment_a) do
          Core::FlightSegment.new(origin_iata: "MAD",
                                  destination_iata: "BCN",
                                  departure_at: Time.parse("2026-01-01 10:00:00 +01:00"),
                                  arrival_at: Time.parse("2026-01-01 11:00:00 +01:00"),
                                  line_number: 1)
        end

        let(:segment_b) do
          Core::FlightSegment.new(origin_iata: "BCN",
                                  destination_iata: "AMS",
                                  departure_at: Time.parse("2026-01-02 11:00:00 +01:00"),
                                  arrival_at: Time.parse("2026-01-02 13:00:00 +01:00"),
                                  line_number: 2)
        end

        let(:segments) { [segment_a, segment_b] }

        it "does not treat the second flight as a connection" do
          trip_builder.build

          expect(segment_b.is_a_connection).to be(false)
        end
      end

      it "marks the trips as closed if there is a flight segment with" \
         " destination in the based city" do
        trip_builder.build

        expect(trip_builder.trips.first.closed?).to be(true)
        expect(trip_builder.trips.last.closed?).to be(true)
      end

      context "when there are no moving segments" do
        let(:segments) { [hotel1] }

        it "fails with a validation error and returns false" do
          expect(trip_builder.build).to be(false)
          expect(trip_builder.errors)
            .to include("No flight/train segments found: cannot infer any trips")
        end
      end

      context "when based_city does not match the first origin but appears later" do
        let(:based_city) { "MAD" }
        let(:segment_a) do
          Core::FlightSegment.new(origin_iata: "BCN", destination_iata: "AMS",
                                  departure_at: Time.parse("2026-01-01 10:00:00 +01:00"),
                                  arrival_at: Time.parse("2026-01-01 12:00:00 +01:00"),
                                  line_number: 1)
        end
        let(:segment_b) do
          Core::FlightSegment.new(origin_iata: "MAD", destination_iata: "BCN",
                                  departure_at: Time.parse("2026-01-02 10:00:00 +01:00"),
                                  arrival_at: Time.parse("2026-01-02 12:00:00 +01:00"),
                                  line_number: 2)
        end
        let(:segments) { [segment_a, segment_b] }

        it "logs the error and returns false" do
          result = trip_builder.build

          expect(result).to be(false)
          expect(trip_builder.errors.join).to match(/does not match the first segment origin/)
        end
      end

      context "when based_city does not match any segment origin" do
        let(:based_city) { "MAD" }
        let(:segment_a) do
          Core::FlightSegment.new(origin_iata: "BCN", destination_iata: "AMS",
                                  departure_at: Time.parse("2026-01-01 10:00:00 +01:00"),
                                  arrival_at: Time.parse("2026-01-01 12:00:00 +01:00"),
                                  line_number: 1)
        end
        let(:segment_b) do
          Core::FlightSegment.new(origin_iata: "AMS", destination_iata: "BCN",
                                  departure_at: Time.parse("2026-01-02 10:00:00 +01:00"),
                                  arrival_at: Time.parse("2026-01-02 12:00:00 +01:00"),
                                  line_number: 2)
        end
        let(:segments) { [segment_a, segment_b] }

        it "logs the error and returns false" do
          result = trip_builder.build

          expect(result).to be(false)
          expect(trip_builder.errors.last)
            .to eq("Based city MAD does not match any segment origin.")
        end
      end

      context "when a first moving segment does not start at based_city" do
        let(:based_city) { "MAD" }
        let(:segments) { [segment2] }

        it "does not create any trip and logs the error" do
          trip_builder.build

          expect(trip_builder.trips).to be_empty
          expect(trip_builder.errors.join)
            .to match(/does not start at base city MAD/)
        end
      end

      context "when a moving segment does not connect with the current trip" \
              " nor base city" do
        let(:departure_at) { Time.parse("2026-01-02 09:00:00 +01:00") }
        let(:arrival_at) { Time.parse("2026-01-02 11:00:00 +01:00") }
        let(:bad_segment) do
          Core::FlightSegment.new(origin_iata: "CDG",
                                  destination_iata: "AMS",
                                  departure_at:,
                                  arrival_at:,
                                  line_number: 99)
        end
        let(:segments) { [segment1, bad_segment, segment3] }

        it "keeps the trip and logs the bad segment error" do
          trip_builder.build

          expect(trip_builder.trips.size).to eq(1)
          expect(trip_builder.errors.join)
            .to match(/Segment at line 99 must start in MAD or end in MAD or connect with the current trip/)
        end
      end

      context "when a hotel segment does not match any trip" do
        let(:check_in_on) { Time.parse("2026-01-12 10:00:00 +01:00") }
        let(:check_out_on) { Time.parse("2026-01-18 11:00:00 +01:00") }
        let(:hotel_far) do
          Core::HotelSegment.new(location_iata: "NYC",
                                 check_in_on:,
                                 check_out_on:,
                                 line_number: 99)
        end
        let(:segments) { [segment1, segment2, segment3, hotel_far] }

        it "logs the error" do
          trip_builder.build

          expect(trip_builder.errors.join).to match(/Hotel at NYC \(line 99\) does not match any trip/)
        end
      end
    end
  end
end
