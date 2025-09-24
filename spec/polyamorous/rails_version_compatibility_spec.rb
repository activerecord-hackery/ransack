require 'spec_helper'

describe "Rails Version Compatibility" do
  describe "Rails 7.2.x compatibility code loading" do
    context "when Rails version is in the 7.2.x range" do
      it "should load compatibility code for Rails 7.2.0" do
        version = Gem::Version.new("7.2.0")
        expect(version >= Gem::Version.new("7.2")).to be true
        expect(version < Gem::Version.new("7.3.0")).to be true
      end

      it "should load compatibility code for Rails 7.2.1" do
        version = Gem::Version.new("7.2.1")
        expect(version >= Gem::Version.new("7.2")).to be true
        expect(version < Gem::Version.new("7.3.0")).to be true
      end

      it "should load compatibility code for Rails 7.2.2" do
        version = Gem::Version.new("7.2.2")
        expect(version >= Gem::Version.new("7.2")).to be true
        expect(version < Gem::Version.new("7.3.0")).to be true
      end

      it "should load compatibility code for Rails 7.2.2.1" do
        version = Gem::Version.new("7.2.2.1")
        expect(version >= Gem::Version.new("7.2")).to be true
        expect(version < Gem::Version.new("7.3.0")).to be true
      end
    end

    context "when Rails version is outside the 7.2.x range" do
      it "should not load compatibility code for Rails 7.1.x" do
        version = Gem::Version.new("7.1.3")
        expect(version >= Gem::Version.new("7.2")).to be false
      end

      it "should not load compatibility code for Rails 7.3.0" do
        version = Gem::Version.new("7.3.0")
        expect(version < Gem::Version.new("7.3.0")).to be false
      end
    end
  end

  describe "actual compatibility behavior" do
    context "when Rails 7.2 compatibility code is loaded" do
      it "should have the JoinAssociationExtensions module available" do
        # This test verifies that if we're in a Rails 7.2.x environment,
        # the compatibility extensions are loaded
        if ::ActiveRecord.version >= ::Gem::Version.new("7.2") && ::ActiveRecord.version < ::Gem::Version.new("7.3.0")
          expect(Polyamorous::JoinAssociationExtensions).to be_a(Module)
          expect(Polyamorous::JoinAssociationExtensions.instance_methods).to include(:join_constraints_with_tables)
        end
      end
    end
  end
end