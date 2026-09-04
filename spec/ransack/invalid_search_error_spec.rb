require 'spec_helper'

module Ransack
  describe InvalidSearchError do
    it 'inherits from ArgumentError' do
      expect(InvalidSearchError.superclass).to eq(ArgumentError)
    end

    it 'can be instantiated with a message' do
      error = InvalidSearchError.new('Test error message')
      expect(error.message).to eq('Test error message')
    end

    it 'can be instantiated without a message' do
      error = InvalidSearchError.new
      expect(error.message).to eq('Ransack::InvalidSearchError')
    end

    it 'can be raised and caught' do
      expect { raise InvalidSearchError.new('Test') }.to raise_error(InvalidSearchError, 'Test')
    end

    it 'can be raised and caught as ArgumentError' do
      expect { raise InvalidSearchError.new('Test') }.to raise_error(ArgumentError, 'Test')
    end
  end
end
