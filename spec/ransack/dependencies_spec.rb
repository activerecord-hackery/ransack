=begin
rails = ::ActiveRecord::VERSION::STRING.first(3)

if %w(3.2 4.0 4.1).include?(rails) || rails == '3.1' && RUBY_VERSION < '2.2'
  describe 'Ransack' do
    it 'can be required without errors' do
      output = `bundle exec ruby -e "require 'ransack'" 2>&1`
      expect(output).to be_empty
    end
  end
end
=end
