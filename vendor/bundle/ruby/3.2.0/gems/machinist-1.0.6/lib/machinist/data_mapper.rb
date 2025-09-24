require 'machinist'
require 'machinist/blueprints'
require 'dm-core'

module Machinist
  
  class DataMapperAdapter
    def self.has_association?(object, attribute)
      object.class.relationships.has_key?(attribute)
    end
    
    def self.class_for_association(object, attribute)
      association = object.class.relationships[attribute]
      association && association.parent_model
    end

    def self.association_is_many_to_one?(association)
      if defined?(DataMapper::Associations::ManyToOne::Relationship)
        # We're using the next branch of DM
        association.class == DataMapper::Associations::ManyToOne::Relationship
      else
        # We're using the 0.9 or less branch.
        association.options[:max].nil?
      end
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
        association = lathe.object.class.relationships[attribute]
        if association && association_is_many_to_one?(association)
          # DataMapper child_key can have more than one property, but I'm not
          # sure in what circumstances this would be the case. I'm assuming
          # here that there's only one property.
          key = association.child_key.map(&:field).first.to_sym
          attributes[key] = value.id
        else
          attributes[attribute] = value
        end
      end
      attributes
    end
  end

  module DataMapperExtensions
    def make(*args, &block)
      lathe = Lathe.run(Machinist::DataMapperAdapter, self.new, *args)
      unless Machinist.nerfed?
        lathe.object.save || raise("Save failed")
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
      lathe = Lathe.run(Machinist::DataMapperAdapter, self.new, *args)
      Machinist::DataMapperAdapter.assigned_attributes_without_associations(lathe)
    end
  end

end

DataMapper::Model.append_extensions(Machinist::Blueprints::ClassMethods)
DataMapper::Model.append_extensions(Machinist::DataMapperExtensions)
