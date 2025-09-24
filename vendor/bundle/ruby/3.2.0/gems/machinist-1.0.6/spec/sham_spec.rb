require File.dirname(__FILE__) + '/spec_helper'
require 'sham'

describe Sham do
  it "should ensure generated values are unique" do
    Sham.clear
    Sham.half_index {|index| index/2 }
    values = (1..10).map { Sham.half_index }
    values.should == (0..9).to_a
  end

  it "should generate non-unique values when asked" do
    Sham.clear
    Sham.coin_toss(:unique => false) {|index| index % 2 == 1 ? 'heads' : 'tails' }
    values = (1..4).map { Sham.coin_toss }
    values.should == ['heads', 'tails', 'heads', 'tails']
  end
  
  it "should generate more than a dozen values" do
    Sham.clear
    Sham.index {|index| index }
    values = (1..25).map { Sham.index }
    values.should == (1..25).to_a
  end
    
  it "should generate the same sequence of values after a reset" do
    Sham.clear
    Sham.random { rand }
    values1 = (1..10).map { Sham.random }
    Sham.reset
    values2 = (1..10).map { Sham.random }
    values2.should == values1
  end

  it "should alias reset with reset(:before_all)" do
    Sham.clear
    Sham.random { rand }
    values1 = (1..10).map { Sham.random }
    Sham.reset(:before_all)
    values2 = (1..10).map { Sham.random }
    values2.should == values1
  end

  it "should generate the same sequence of values after each reset(:before_each)" do
    Sham.clear
    Sham.random { rand }
    values1 = (1..10).map { Sham.random }
    Sham.reset(:before_each)
    values2 = (1..10).map { Sham.random }
    Sham.reset(:before_each)
    values3 = (1..10).map { Sham.random }
    values2.should_not == values1
    values3.should == values2
  end

  it "should generate a different sequence of values after reset(:before_all) followed by reset(:before_each)" do
    Sham.clear
    Sham.random { rand }
    (1..10).map { Sham.random }
    Sham.reset(:before_each)
    values1 = (1..10).map { Sham.random }
    Sham.reset(:before_all)
    (1..5).map { Sham.random }
    Sham.reset(:before_each)
    values2 = (1..10).map { Sham.random }
    values2.should_not == values1
  end

  it "should die when it runs out of unique values" do
    Sham.clear
    Sham.limited {|index| index%10 }
    lambda {
      (1..100).map { Sham.limited }
    }.should raise_error(RuntimeError)
  end
  
  it "should allow over-riding the name method" do
    Sham.clear
    Sham.name  {|index| index }
    Sham.name.should == 1
  end
  
  describe "define method" do
    it "should repeat messages in its block to Sham" do
      block = Proc.new {}
      Sham.should_receive(:name).with(&block).once.ordered
      Sham.should_receive(:slug).with(:arg, &block).once.ordered
      Sham.define do
        name &block
        slug :arg, &block
      end
    end
  end
  
end
