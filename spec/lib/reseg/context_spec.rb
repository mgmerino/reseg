# frozen_string_literal: true

module Reseg
  RSpec.describe Context do
    let(:based_city) { "MAD" }
    let(:time_zone) { "Europe/Madrid" }
    let(:context) { described_class.new(based_city: based_city, time_zone: time_zone) }

    describe "#initialize" do
      it "sets the based city" do
        expect(context.based_city).to eq("MAD")
      end

      it "sets the time zone" do
        expect(context.time_zone).to eq("Europe/Madrid")
      end

      context "when the time zone is not provided" do
        let(:time_zone) { nil }
        it "uses the default time zone" do
          expect(context.time_zone).to eq("UTC")
        end
      end

      context "when the time zone and the location resolver are not provided" do
        let(:time_zone) { nil }
        it "uses the default time zone" do
          expect(context.time_zone).to eq("UTC")
        end
      end
    end
  end
end
