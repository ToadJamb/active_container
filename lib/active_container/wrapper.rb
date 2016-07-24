module ActiveContainer
  class Wrapper
    attr_reader :record

    def initialize(record)
      if record.is_a?(Hash)
        @record = self.class.object_class.new(record)
      else
        @record = record
      end
    end

    class << self
      def wrap(record)
        return nil unless record

        if self == Wrapper
          wrapper_name = record.class.name
          wrapper_name += 'Wrapper'

          wrapper = Kernel.const_get(wrapper_name)

          wrapper.new(record)
        else
          self.new record
        end
      end

      def wrap_collection(records)
        return [] unless records

        records.map do |record|
          self.wrap record
        end
      end

      def object_class
        return nil if self == Wrapper
        return @object_class if defined?(@object_class)
        object_class = self.name.gsub(/Wrapper/, '')
        @object_class = Kernel.const_get(object_class)
      end

      private

      def delegate(*delegates)
        delegates.each do |delegate|
          define_method delegate do |*args|
            @record.send(delegate, *args)
          end

          unless self.method_defined?("#{delegate}=")
            define_method "#{delegate}=" do |*args|
              @record.send("#{delegate}=", *args)
            end
          end
        end
      end

      def wrap_delegate(*delegates)
        delegates.each do |delegate|
          # Using specific wrappers here seems to work,
          # but introduces dependencies at load time
          # that may be unavoidably circular.
          define_method delegate do |*args|
            result = @record.send(delegate, *args)

            if delegate.to_s.singularize == delegate.to_s
              Wrapper.wrap result
            else
              Wrapper.wrap_collection result
            end
          end
        end
      end
    end

    [
      :id,
      :save,
      :save!,
      :reload,
      :errors,
    ].each do |method|
      define_method method do |*args|
        @record.send(method, *args)
      end
    end

    def wrapped?
      true
    end
  end
end
