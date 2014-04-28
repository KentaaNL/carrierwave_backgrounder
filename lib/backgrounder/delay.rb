module CarrierWave
  module Backgrounder

    module Delay
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def process(*args)
          new_processors = args.inject({}) do |hash, arg|
            arg = { arg => [] } unless arg.is_a?(Hash)
            hash.merge!(arg)
          end

          condition = new_processors.delete(:if)
          delay = new_processors.has_key?(:delay) ? new_processors.delete(:delay) : true
          new_processors.each do |processor, processor_args|
            self.processors += [[processor, processor_args, condition, delay]]
          end
        end
      end

      def cache_versions!(new_file)
        super if proceed_with_versioning?
      end

      def store_versions!(*args)
        super if proceed_with_versioning?
      end

      def process!(new_file=nil)
        return unless enable_processing

        self.class.processors.each do |method, args, condition, delay|
          next if delay && !proceed_with_versioning?

          if condition
            if condition.respond_to?(:call)
              next unless condition.call(self, :args => args, :method => method, :file => new_file)
            else
              next unless self.send(condition, new_file)
            end
          end
          self.send(method, *args)
        end
      end

      private

      def proceed_with_versioning?
        !model.respond_to?(:"process_#{mounted_as}_upload") && enable_processing ||
          !!(model.send(:"process_#{mounted_as}_upload") && enable_processing)
      end
    end # Delay

  end # Backgrounder
end # CarrierWave
