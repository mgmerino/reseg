# frozen_string_literal: true

module Reseg
  module Core
    RSpec.describe Reservation do
      let(:reservation) { described_class.new(start_line_number: 1) }

      describe "#initialize" do
        it "initializes a reservation object" do
          expect(reservation).to be_a(described_class)
        end
      end

      describe "#add_segment" do
        let(:segment) { Core::Segment.new(starts_at: Time.now, ends_at: Time.now + 1.hour, line_number: 1) }

        it "adds a segment to the reservation" do
          expect(reservation.segments).to be_empty
          reservation.add_segment(segment)
          expect(reservation.segments).to eq([segment])
        end
      end

      describe "#validate!" do
        it "raises an error if the reservation has no segments" do
          expect { reservation.validate! }.to raise_error(Reservation::ValidationError)
        end
      end
    end
  end
end
