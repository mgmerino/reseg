# frozen_string_literal: true

module Reseg
  module Core
    RSpec.describe Segment do
      let(:starts_at) { Time.parse("2026-01-01 10:00:00") }
      let(:ends_at) { Time.parse("2026-01-01 12:00:00") }
      let(:line_number) { 1 }

      describe "#initialize" do
        it "raises an error if the starts_at value is invalid" do
          expect { described_class.new(starts_at: "not a time", ends_at: ends_at, line_number: line_number) }
            .to raise_error(described_class::ValidationError, "starts_at must be a Time object")
        end

        it "raises an error if the ends_at value is invalid" do
          expect { described_class.new(starts_at: starts_at, ends_at: "not a time", line_number: line_number) }
            .to raise_error(described_class::ValidationError, "ends_at must be a Time object")
        end

        it "raises an error if the ends_at value is less than the starts_at value" do
          expect { described_class.new(starts_at: starts_at, ends_at: starts_at - 2.hour, line_number: line_number) }
            .to raise_error(described_class::ValidationError, "ends_at must be >= starts_at")
        end
      end

      describe "#duration" do
        it "returns the duration of the segment" do
          expect(described_class.new(starts_at: starts_at, ends_at: ends_at,
                                     line_number: line_number).duration).to eq(2.hours)
        end
      end
    end
  end
end
