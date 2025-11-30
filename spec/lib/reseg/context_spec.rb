# frozen_string_literal: true

require "ostruct"

module Reseg
  RSpec.describe Context do
    let(:based_city) { "MAD" }
    let(:time_zone) { nil }
    let(:location_resolver) { FakeLocationResolver }
    let(:context) do
      described_class.new(based_city: based_city, time_zone: time_zone, location_resolver: location_resolver)
    end

    describe "#initialize" do
      context "when the based city is not valid" do
        let(:based_city) { "NOT-VALID" }
        it "raises an error" do
          expect { context }.to raise_error(ArgumentError, "Based city must be a 3 letter string")
        end
      end

      context "when the based city cannot be resolved" do
        let(:based_city) { "123" }
        it "raises an error" do
          expect { context }.to raise_error(ArgumentError, "Based city must be a valid IATA code")
        end
      end

      context "when the time zone is not a string" do
        let(:time_zone) { Object.new }
        it "raises an error" do
          expect { context }.to raise_error(ArgumentError, "Time zone must be a string")
        end
      end

      context "when the time zone is not valid" do
        let(:time_zone) { "NOT-VALID" }
        it "raises an error" do
          expect { context }.to raise_error(ArgumentError, "Time zone must be a valid time zone")
        end
      end

      context "when the time zone is not provided" do
        let(:time_zone) { nil }

        it "uses the resolver's time zone" do
          expect(context.time_zone).to eq("Europe/Madrid")
        end
      end

      context "when the time zone and the location resolver are not provided" do
        let(:time_zone) { nil }
        let(:location_resolver) { nil }

        it "uses the default time zone" do
          expect(context.time_zone).to eq("UTC")
        end
      end

      it "sets the based city" do
        expect(context.based_city).to eq("MAD")
      end

      it "sets the time zone" do
        expect(context.time_zone).to eq("Europe/Madrid")
      end

      context "when the time zone is provided" do
        let(:time_zone) { "Europe/London" }
        it "overrides the resolver's time zone" do
          expect(context.time_zone).to eq("Europe/London")
        end
      end
    end
  end

  module FakeLocationResolver
    module_function

    def find_by_iata_code(iata_code)
      case iata_code
      when "MAD"
        OpenStruct.new(tz_name: "Europe/Madrid")
      end
    end
  end
end
