# frozen_string_literal: true

module Reseg
  module Parsing
    RSpec.describe Statement do
      let(:statement) do
        described_class.new(type: type,
                            value: value,
                            line_number: 1,
                            raw: "raw line content")
      end

      describe "#initialize" do
        let(:value) { nil }

        context "when the statement type is valid" do
          let(:type) { Statement::RESERVATION_START }

          it "initializes a statement object" do
            expect(statement).to be_a(described_class)
          end
        end

        context "when the statement type is invalid" do
          let(:type) { :invalid }

          it "raises an error" do
            expect { statement }.to raise_error(ArgumentError)
          end
        end

        context "when the type is reservation start and the value is not nil" do
          let(:type) { Statement::RESERVATION_START }
          let(:value) { "-" }

          it "raises an error" do
            expect { statement }.to raise_error(ArgumentError)
          end
        end

        context "when the statement type is segment line and the value is nil" do
          let(:type) { Statement::SEGMENT_LINE }
          let(:value) { nil }

          it "raises an error" do
            expect { statement }.to raise_error(ArgumentError)
          end
        end
      end

      describe "#reservation_start?" do
        let(:type) { Statement::RESERVATION_START }
        let(:value) { nil }

        it "returns true when the statement type is reservation start" do
          expect(statement.reservation_start?).to be_truthy
        end
      end

      describe "#segment_line?" do
        let(:type) { Statement::SEGMENT_LINE }
        let(:value) { "SEGMENT:" }

        it "returns true when the statement type is segment line" do
          expect(statement.segment_line?).to be_truthy
        end
      end

      describe "#unknown?" do
        let(:type) { Statement::UNKNOWN }
        let(:value) { nil }

        it "returns true when the statement type is unknown" do
          expect(statement.unknown?).to be_truthy
        end
      end

      describe "#to_s" do
        let(:type) { Statement::SEGMENT_LINE }
        let(:value) { "SEGMENT:" }

        it "returns a string representation of the statement" do
          expect(statement.to_s).to eq("#<Statement type=:segment_line line_number=1 value=\"SEGMENT:\">")
        end
      end
    end
  end
end
