require 'spec_helper'

module Ransack
  describe Search do
    describe '#ransack' do
      context 'parameters provided in a harmonious order' do
        it 'produces the expected result' do
          result = ProviderCalendar.
                  ransack({ "account_email_cont" => "account1", "user_email_eq" => "user2@somedomain.com" }).
                  result.
                  map(&:provider_id)

          expect(result).to eq(["account1_user2@mail.com", "aksshkdhak@whatever.provider.com"])
        end
      end

      context 'parameters provided in a disharmonious order' do
        it 'produces the expected result' do
          result = ProviderCalendar.
                   ransack({ "user_email_eq" => "user2@somedomain.com", "account_email_cont" => "account1" }).
                   result.
                   map(&:provider_id)

          expect(result).to eq(["account1_user2@mail.com", "aksshkdhak@whatever.provider.com"])
        end
      end
    end
  end
end
