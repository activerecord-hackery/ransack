require 'machinist'
require 'machinist/blueprints'
require 'sequel'

module Machinist
  class SequelAdapter
    def self.has_association?(object, attribute)
      object.class.associations.include?(attribute)
    end

    def self.class_for_association(object, attribute)
      object.class.association_reflection(attribute).associated_class
    end

    def self.assigned_attributes_without_associations(lathe)
      attributes = {}
      lathe.assigned_attributes.each_pair do |attribute, value|
        association = lathe.object.class.association_reflection(attribute)
        if association && association[:type] == :many_to_one
          key = association[:key] || association.default_key
          attributes[key] = value.send(association.primary_key)
        else
          attributes[attribute] = value
        end
      end
      attributes
    end
  end

  module SequelExtensions
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def make(*args, &block)
        lathe = Lathe.run(Machinist::SequelAdapter, self.new, *args)
        unless Machinist.nerfed?
          lathe.object.save
          lathe.object.refresh
        end
        lathe.object(&block)
      end

      def make_unsaved(*args)
        returning(Machinist.with_save_nerfed { make(*args) }) do |object|
          yield object if block_given?
        end
      end

      def plan(*args)
        lathe = Lathe.run(Machinist::SequelAdapter, self.new, *args)
        Machinist::SequelAdapter.assigned_attributes_without_associations(lathe)
      end      
    end
  end
end

class Sequel::Model
  include Machinist::Blueprints
  include Machinist::SequelExtensions
end
