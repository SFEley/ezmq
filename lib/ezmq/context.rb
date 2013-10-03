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

      # Clean up if garbage collected
      @destroyer = self.class.finalize(ptr)
      ObjectSpace.define_finalizer self, @destroyer
    end

    # Options

    # The size of the 0MQ thread pool for this context.
    def io_threads
      API::invoke :zmq_ctx_get, ptr, Options[:io_threads]
    end

    # Specifies the size of the 0MQ thread pool to handle I/O
    # operations. If your application is using only the inproc transport
    # for messaging you may set this to zero, otherwise set it to at
    # least one. This option only applies before creating any sockets
    # on the context.
    def io_threads=(val)
      API::invoke :zmq_ctx_set, ptr, Options[:io_threads], val
    end

    # Returns the maximum number of sockets allowed for this context.
    def max_sockets
      API::zmq_ctx_get(ptr, Options[:max_sockets])
    end

    # Sets the maximum number of sockets allowed on the context.
    def max_sockets=(val)
      API::zmq_ctx_set(ptr, Options[:max_sockets], val)
    end

    # Closes any sockets and terminates the 0mq context. Attempting to
    # access the context or any sockets after this will throw an exception.
    # @note This also occurs when the Context object is garbage collected.
    def destroy
      destroyer.call
    end


    # Creates a routine that will safely close any sockets and terminate
    # the 0mq context upon garbage collection.
    def self.finalize(ptr)
      Proc.new do
        API::zmq_ctx_destroy(ptr)
      end
    end

  private
    attr_reader :destroyer


  end
end
