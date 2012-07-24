require 'sunspot'
require 'sunspot/rails'

module Sunspot
  module Mongo
    def self.included(base)
      base.class_eval do
        extend Sunspot::Rails::Searchable::ActsAsMethods
        extend ClassMethods
        Sunspot::Adapters::DataAccessor.register(DataAccessor, base)
        Sunspot::Adapters::InstanceAdapter.register(InstanceAdapter, base)
      end
    end

    module ClassMethods
      def batched_solr_index(batch_size = 1000)
        (count / Float(batch_size)).ceil.times do |i|
          all.order_by([['_id', ::Mongo::ASCENDING]])
             .skip(i * batch_size)
             .limit(batch_size).each do |instance|
            instance.index
          end
          Sunspot.commit
        end        
      end
    end

    class InstanceAdapter < Sunspot::Adapters::InstanceAdapter
      def id
        @instance.id
      end
    end

    class DataAccessor < Sunspot::Adapters::DataAccessor
      def load(id)
        @clazz.where(_id: id).first
      end

      def load_all(ids)
        @clazz.any_in(_id: ids).to_a
      end
    end
  end
end
