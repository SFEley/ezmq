require 'ezmq/context'

module EZMQ
  class Context

    # Changes between 0mq 3.2.x and 0mq 4.0.x.
    module Zmq4_0
      module ClassOverrides
        # Creates a routine that will safely close any sockets and terminate
        # the 0MQ context upon garbage collection.
        def finalize(ptr, sockets)
          Proc.new do
            API::invoke :zmq_ctx_shutdown, ptr  # Recommended for 4.x
            sockets.each { |socket| socket.close }
            API::invoke :zmq_ctx_term, ptr
          end
        end
      end

      def self.included(target)
        class << target
          prepend ClassOverrides
        end
      end
    end
  end
end
