require 'machinist'
require 'machinist/blueprints'
require 'active_record'

module Machinist
  
  class ActiveRecordAdapter
    
    def self.has_association?(object, attribute)
      object.class.reflect_on_association(attribute)
    end
    
    def self.class_for_association(object, attribute)
      association = object.class.reflect_on_association(attribute)
      association && association.klass
    end
    
    # This method takes care of converting any associated objects,
    # in the hash returned by Lathe#assigned_attributes, into their
    # object ids.
    #
    # For example, let's say we have blueprints like this:
    #
    #   Post.blueprint { }
    #   Comment.blueprint { post }
    #
    # Lathe#assigned_attributes will return { :post => ... }, but
    # we want to pass { :post_id => 1 } to a controller.
    #
    # This method takes care of cleaning this up.
    def self.assigned_attributes_without_associations(lathe)
      attributes = {}
      lathe.assigned_attributes.each_pair do |attribute, value|
        association = lathe.object.class.reflect_on_association(attribute)
        if association && association.macro == :belongs_to && !value.nil?
          attributes[association.primary_key_name.to_sym] = value.id
        else
          attributes[attribute] = value
        end
      end
      attributes
    end
    
  end
    
  module ActiveRecordExtensions
    def self.included(base)
      base.extend(ClassMethods)
    end
  
    module ClassMethods
      def make(*args, &block)
        lathe = Lathe.run(Machinist::ActiveRecordAdapter, self.new, *args)
        unless Machinist.nerfed?
          lathe.object.save!
          lathe.object.reload
        end
        lathe.object(&block)
      end

      def make_unsaved(*args)
        object = Machinist.with_save_nerfed { make(*args) }
        yield object if block_given?
        object
      end
        
      def plan(*args)
        lathe = Lathe.run(Machinist::ActiveRecordAdapter, self.new, *args)
        Machinist::ActiveRecordAdapter.assigned_attributes_without_associations(lathe)
      end
    end
  end
  
  module ActiveRecordHasManyExtensions
    def make(*args, &block)
      lathe = Lathe.run(Machinist::ActiveRecordAdapter, self.build, *args)
      unless Machinist.nerfed?
        lathe.object.save!
        lathe.object.reload
      end
      lathe.object(&block)
    end

    def plan(*args)
      lathe = Lathe.run(Machinist::ActiveRecordAdapter, self.build, *args)
      Machinist::ActiveRecordAdapter.assigned_attributes_without_associations(lathe)
    end
  end

end

class ActiveRecord::Base
  include Machinist::Blueprints
  include Machinist::ActiveRecordExtensions
end

class ActiveRecord::Associations::HasManyAssociation
  include Machinist::ActiveRecordHasManyExtensions
end
