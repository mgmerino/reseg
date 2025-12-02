# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Reseg
  module Core
    # rubocop:disable Metrics/BlockLength
    RSpec.describe Trip do
      let(:trip) { described_class.new(based_city: "MAD") }
      let(:from_date) { Time.parse("2026-01-01 10:00:00") }
      let(:to_date) { Time.parse("2026-01-02 10:00:00") }
      let(:flight_segment) { Core::FlightSegment.new(origin_iata: "MAD", destination_iata: "BCN", departure_at: from_date, arrival_at: to_date, line_number: 1) }
      let(:train_segment) { Core::TrainSegment.new(origin_iata: "BCN", destination_iata: "MAD", departure_at: from_date + 2.days, arrival_at: to_date + 50.hours, line_number: 1) }
      let(:hotel_segment) { Core::HotelSegment.new(location_iata: "BCN", check_in_on: from_date, check_out_on: to_date, line_number: 1) }

      describe "#initialize" do
        it "initializes a trip object" do
          expect(trip).to be_a(described_class)
        end
      end

      describe "#close" do
        context "when the trip has segments" do
          before do
            trip.add_segment(flight_segment)
          end

          it "closes the trip" do
            expect(trip.closed?).to be(false)

            trip.close

            expect(trip.closed?).to be(true)
            expect(trip.destination_iata).to eq("BCN")
          end
        end

        context "when the trip is already closed" do
          before do
            allow(trip).to receive(:closed?).and_return(true)
          end

          it "raises a validation error" do
            expect { trip.close }.to raise_error(described_class::ValidationError)
          end
        end

        context "when the trip has no segments" do
          it "raises a validation error" do
            expect { trip.close }.to raise_error(described_class::ValidationError)
          end
        end
      end

      describe "#add_segment" do
        it "adds a segment to the trip" do
          expect(trip.segments).to be_empty
          trip.add_segment(flight_segment)
          expect(trip.segments).to eq([flight_segment])
        end

        context "when the trip is closed" do
          before do
            allow(trip).to receive(:closed?).and_return(true)
          end

          it "raises a validation error" do
            expect { trip.add_segment(flight_segment) }.to raise_error(described_class::ValidationError)
          end
        end
      end

      describe "#insert_hotel_segment" do
        context "when the trip has segments that match the hotel segment" do
          before do
            trip.add_segment(flight_segment)
            trip.add_segment(train_segment)
          end

          it "inserts a hotel segment into the correct position" do
            trip.insert_hotel_segment(hotel_segment)
            expect(trip.segments).to eq([flight_segment, hotel_segment, train_segment])
          end
        end

        context "when the trip has no segments" do
          it "raises a validation error" do
            expect { trip.insert_hotel_segment(hotel_segment) }.to raise_error(described_class::ValidationError)
          end
        end

        context "when the hotel segment does not match any segment" do
          let(:hotel_segment) { Core::HotelSegment.new(location_iata: "NYC", check_in_on: Date.today, check_out_on: Date.today + 1.day, line_number: 1) }

          it "raises a validation error" do
            expect { trip.insert_hotel_segment(hotel_segment) }.to raise_error(described_class::ValidationError)
          end
        end
      end

      describe "#matches_hotel?" do
        before do
          trip.add_segment(flight_segment)
          trip.destination_iata = "BCN"
        end

        it "returns true if the hotel segment matches the trip destination and dates" do
          expect(trip.matches_hotel?(hotel_segment)).to be(true)
        end

        context "when the hotel segment does not match the trip destination" do
          let(:hotel_segment) { Core::HotelSegment.new(location_iata: "NYC", check_in_on: from_date, check_out_on: to_date, line_number: 1) }

          it "returns false if the hotel segment does not match the trip destination" do
            expect(trip.matches_hotel?(hotel_segment)).to be(false)
          end
        end

        context "when the hotel segment does not match the trip dates" do
          let(:hotel_segment) { Core::HotelSegment.new(location_iata: "BCN", check_in_on: from_date + 1.day, check_out_on: to_date + 2.days, line_number: 1) }

          it "returns false if the hotel segment does not match the trip dates" do
            expect(trip.matches_hotel?(hotel_segment)).to be(false)
          end
        end
      end

      describe "#departure_date" do
        before do
          trip.add_segment(flight_segment)
        end

        it "returns the departure date of the trip" do
          expect(trip.departure_date).to eq(from_date.to_date)
        end
      end

      describe "#arrival_date" do
        before do
          trip.add_segment(flight_segment)
        end

        it "returns the arrival date of the trip" do
          expect(trip.arrival_date).to eq(to_date.to_date)
        end
      end

      describe "#duration" do
        before do
          trip.add_segment(flight_segment)
          trip.add_segment(hotel_segment)
          trip.add_segment(train_segment)
        end

        it "returns the duration of the trip" do
          expect(trip.duration).to eq(2.days)
        end
      end

      describe "#last_flight_not_connection" do
        let(:flight_segment) { Core::FlightSegment.new(origin_iata: "MAD", destination_iata: "BCN", departure_at: from_date, arrival_at: from_date + 2.hours, line_number: 1) }
        let(:connection_segment) { Core::FlightSegment.new(origin_iata: "BCN", destination_iata: "CDG", departure_at: from_date + 3.hours, arrival_at: from_date + 5.hours, line_number: 1) }
        let(:round_trip_flight_segment) { Core::FlightSegment.new(origin_iata: "CDG", destination_iata: "MAD", departure_at: from_date + 2.days, arrival_at: to_date + 52.hours, line_number: 1) }

        before do
          trip.add_segment(flight_segment)
          trip.add_segment(connection_segment)
          trip.add_segment(round_trip_flight_segment)
        end

        it "returns the last flight segment that is not a connection" do
          expect(trip.last_flight_not_connection).to eq(round_trip_flight_segment)
        end

        context "when the trip has no flight segments" do
          before do
            trip.segments.clear
          end

          it "returns nil" do
            expect(trip.last_flight_not_connection).to be_nil
          end
        end
      end
    end
  end
  # rubocop:enable Metrics/BlockLength
end
# rubocop:enable Metrics/ModuleLength
