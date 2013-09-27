require 'ezmq/api'

module EZmq
  class Context

    # From include/zmq.h
    Options = {
      io_threads:   1,
      max_sockets:  2
    }.freeze

    attr_reader :ptr

    def initialize
      @ptr = API::zmq_ctx_new
    end

    # Options

    # The size of the 0MQ thread pool for this context.
    def io_threads
      API::zmq_ctx_get(ptr, Options[:io_threads])
    end

    # Specifies the size of the 0MQ thread pool to handle I/O
    # operations. If your application is using only the inproc transport
    # for messaging you may set this to zero, otherwise set it to at
    # least one. This option only applies before creating any sockets
    # on the context.
    def io_threads=(val)
      API::zmq_ctx_set(ptr, Options[:io_threads], val)
    end

    # Returns the maximum number of sockets allowed for this context.
    def max_sockets
      API::zmq_ctx_get(ptr, Options[:max_sockets])
    end

    # Sets the maximum number of sockets allowed on the context.
    def max_sockets=(val)
      API::zmq_ctx_set(ptr, Options[:max_sockets], val)
    end


    def destroy
      API::zmq_ctx_destroy(ptr)
    end

  end
end
