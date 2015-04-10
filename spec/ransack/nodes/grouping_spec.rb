require 'spec_helper'

module Ransack
  module Nodes
    describe Grouping do

      before do
        @g = 1
      end

      let(:context) { Context.for(Person) }

      subject { described_class.new(context) }

      describe '#attribute_method?' do
        context 'for attributes of the context' do
          it 'is true' do
            expect(subject.attribute_method?('name')).to be true
          end

          context "when the attribute contains '_and_'" do
            it 'is true' do
              expect(subject.attribute_method?('terms_and_conditions')).to be true
            end
          end

          context "when the attribute contains '_or_'" do
            it 'is true' do
              expect(subject.attribute_method?('true_or_false')).to be true
            end
          end

          context "when the attribute ends with '_start'" do
            it 'is true' do
              expect(subject.attribute_method?('life_start')).to be true
            end
          end

          context "when the attribute ends with '_end'" do
            it 'is true' do
              expect(subject.attribute_method?('stop_end')).to be true
            end
          end
        end

        context 'for unknown attributes' do
          it 'is false' do
            expect(subject.attribute_method?('not_an_attribute')).to be false
          end
        end
      end

    end
  end
end
