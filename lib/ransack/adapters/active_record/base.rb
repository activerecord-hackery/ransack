module Ransack
  module Adapters
    module ActiveRecord
      module Base

        def self.extended(base)
          alias :search :ransack unless base.method_defined? :search
          base.class_eval do
            class_attribute :_ransackers
            self._ransackers ||= {}
            class_attribute :_spare
            self._spare ||=[]
          end
        end

        def ransack(params = {}, options = {})
          Search.new(self, params, options)
        end

        def ransacker(name, opts = {}, &block)
          self._ransackers = _ransackers.merge name.to_s => Ransacker.new(self, name, opts, &block)
        end
        #Commonly requested feature for models current methodology is to redefine ransackable_attributes for each model
        #spare_from_ransack will accept a list of attributes and remove them from ransackable_attributes
        #this method allows for dynamic reconstruction of the ransackable_attributes and also provides some short cut methods such as :time_stamps, :association_keys, :primary
        def spare_from_ransack(*attribs)
          self._spare = attribs.map do |a| 
            case a.to_sym
              #remove time_stamp fields 
              when :time_stamps
                ["created_at","updated_at"]
              #requires spare_from_ransack to be called after associations in the file
              when :association_keys
                reflect_on_all_associations.select{|a| a.macro == :belongs_to}.collect{|a| a.options[:foreign_key] || "#{a.name}_id"}
              #remove primary key field 
              when :primary
                primary_key
              else
                a.to_s
            end
          end.flatten
        end
        def ransackable_attributes(auth_object = nil)
          (column_names - _spare) + _ransackers.keys
        end

        def ransortable_attributes(auth_object = nil)
          # Here so users can overwrite the attributes that show up in the sort_select
          ransackable_attributes(auth_object)
        end

        def ransackable_associations(auth_object = nil)
          reflect_on_all_associations.map {|a| a.name.to_s}
        end


      end
    end
  end
end
