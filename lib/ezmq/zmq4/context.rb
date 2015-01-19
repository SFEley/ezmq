require_relative '../zmq3/context'

module EZMQ
  class Context
    # Creates a routine that will safely close any sockets and terminate
    # the 0MQ context upon garbage collection.
    def self.finalize(ptr, sockets)
      Proc.new do
        API::invoke :zmq_ctx_shutdown, ptr  # Recommended for 4.x
        sockets.each { |socket| socket.close }
        API::invoke :zmq_ctx_term, ptr
      end
    end
  end
end
