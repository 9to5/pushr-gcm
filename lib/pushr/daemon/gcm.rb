module Pushr
  module Daemon
    class Gcm
      attr_accessor :configuration
      def initialize(options)
        self.configuration = options
      end

      def connectiontype
        GcmSupport::ConnectionGcm
      end

      def stop
        true
      end
    end
  end
end
