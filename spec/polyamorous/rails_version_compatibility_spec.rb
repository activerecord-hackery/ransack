require 'spec_helper'

module Polyamorous
  describe "Rails Version Compatibility" do
    describe "Rails 7.2.x compatibility code loading" do
      context "version boundary checks" do
        it "includes Rails 7.2.0 in compatibility range" do
          version = Gem::Version.new("7.2.0")
          expect(version >= Gem::Version.new("7.2")).to be true
          expect(version < Gem::Version.new("7.3.0")).to be true
        end

        it "includes Rails 7.2.1 in compatibility range" do
          version = Gem::Version.new("7.2.1")
          expect(version >= Gem::Version.new("7.2")).to be true
          expect(version < Gem::Version.new("7.3.0")).to be true
        end

        it "excludes Rails 7.1.x from compatibility range" do
          version = Gem::Version.new("7.1.3")
          expect(version >= Gem::Version.new("7.2")).to be false
        end

        it "excludes Rails 7.3.0 from compatibility range" do
          version = Gem::Version.new("7.3.0")
          expect(version < Gem::Version.new("7.3.0")).to be false
        end

        it "excludes Rails 8.0 from compatibility range" do
          version = Gem::Version.new("8.0.0")
          expect(version < Gem::Version.new("7.3.0")).to be false
        end
      end
    end
  end
end