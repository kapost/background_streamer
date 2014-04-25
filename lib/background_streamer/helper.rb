module BackgroundStreamer
  module Helper
    class << self
      def included(base)
        base.extend(ClassMethods)
      end
    end

    module ClassMethods
      def create_stream_manager name, options = {}
        manager = Manager.new(options)

        define_method name.to_sym do
          manager
        end
      end
    end
  end
end