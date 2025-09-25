require 'spec_helper'

module Ransack
  describe Ransacker do
    let(:klass) { Person }
    let(:name) { :test_ransacker }
    let(:opts) { {} }

    describe '#initialize' do
      context 'with minimal options' do
        subject { Ransacker.new(klass, name, opts) }

        it 'sets the name' do
          expect(subject.name).to eq(name)
        end

        it 'sets default type to string' do
          expect(subject.type).to eq(:string)
        end

        it 'sets default args to [:parent]' do
          expect(subject.args).to eq([:parent])
        end
      end

      context 'with custom options' do
        let(:opts) { { type: :integer, args: [:parent, :custom_arg], formatter: proc { |v| v.to_i } } }

        subject { Ransacker.new(klass, name, opts) }

        it 'sets the custom type' do
          expect(subject.type).to eq(:integer)
        end

        it 'sets the custom args' do
          expect(subject.args).to eq([:parent, :custom_arg])
        end

        it 'sets the formatter' do
          expect(subject.formatter).to eq(opts[:formatter])
        end
      end

      context 'with callable option' do
        let(:callable) { proc { |parent| parent.table[:id] } }
        let(:opts) { { callable: callable } }

        subject { Ransacker.new(klass, name, opts) }

        it 'initializes successfully' do
          expect(subject).to be_a(Ransacker)
        end
      end
    end

    describe 'basic functionality' do
      subject { Ransacker.new(klass, name, opts) }

      it 'responds to required methods' do
        expect(subject).to respond_to(:name)
        expect(subject).to respond_to(:type)
        expect(subject).to respond_to(:args)
        expect(subject).to respond_to(:formatter)
        expect(subject).to respond_to(:attr_from)
        expect(subject).to respond_to(:call)
      end
    end
  end
end
