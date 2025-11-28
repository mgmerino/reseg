# frozen_string_literal: true

module Reseg
  module Parsing
    RSpec.describe Scanner do
      let(:scanner) do
        described_class.new(input)
      end

      describe "#initialize" do
        let(:input) do
          <<~TXT
            RESERVATION
            SEGMENT: Flight IATA_CODE ISO_EXTENDED_DATE HH:MM:SS -> IATA_CODE HH:MM:SS
          TXT
        end

        it "initializes a scanner object" do
          expect(scanner).to be_a(described_class)
        end

        context "when the input is a file" do
          let(:input) { File.open("spec/fixtures/input.txt") }

          it "initializes a scanner object" do
            expect(scanner).to be_a(described_class)
          end
        end

        context "when the input is not supported" do
          let(:input) { Object.new }

          it "raises an error" do
            expect { scanner }.to raise_error(ArgumentError)
          end
        end
      end

      describe "#each" do
        let(:scanner) { described_class.new(input) }

        let(:input) do
          <<~TXT
            RESERVATION
            SEGMENT: Flight MAD 2025-24-11 09:00:00 -> BCN 10:30:00

            SEGMENT malformed
            foo bar
          TXT
        end

        it "yields the expected statements in order" do
          statements = scanner.to_a

          expect(statements.size).to eq(4)

          res, seg, _, unknown = statements

          expect(res).to have_attributes(
            type: Statement::RESERVATION_START,
            value: nil,
            line_number: 1
          )

          expect(seg).to have_attributes(
            type: Statement::SEGMENT_LINE,
            value: "Flight MAD 2025-24-11 09:00:00 -> BCN 10:30:00",
            line_number: 2
          )

          expect(unknown).to have_attributes(
            type: Statement::UNKNOWN,
            value: "foo bar",
            line_number: 5
          )
        end
      end
    end
  end
end
