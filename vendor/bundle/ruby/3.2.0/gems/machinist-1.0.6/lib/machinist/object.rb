require 'machinist'
require 'machinist/blueprints'

module Machinist
  
  module ObjectExtensions
    def self.included(base)
      base.extend(ClassMethods)
    end
  
    module ClassMethods
      def make(*args, &block)
        lathe = Lathe.run(Machinist::ObjectAdapter, self.new, *args)
        lathe.object(&block)
      end
    end
  end
  
  class ObjectAdapter
    def self.has_association?(object, attribute)
      false
    end
  end
  
end

class Object
  include Machinist::Blueprints
  include Machinist::ObjectExtensions
end
