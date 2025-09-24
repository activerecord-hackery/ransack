module Machinist
  # Include this in a class to allow defining blueprints for that class.
  module Blueprints
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def blueprint(name = :master, &blueprint)
        @blueprints ||= {}
        @blueprints[name] = blueprint if block_given?
        @blueprints[name]
      end
    
      def named_blueprints
        @blueprints.reject{|name,_| name == :master }.keys
      end
    
      def clear_blueprints!
        @blueprints = {}
      end
    end
    
  end
end
