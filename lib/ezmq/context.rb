require 'monitor'

require 'ezmq/api'
require 'ezmq/loggable'

module EZMQ

  class Context
    include Loggable


    # From include/zmq.h
    Options = {
      io_threads:   1,
      max_sockets:  2
    }.freeze

    # The sockets attached to this context. All sockets will be closed when
    # the context is terminated or goes out of scope.
    attr_reader :sockets

    # Creates a new 0MQ context. Hooks are also established to terminate it
    # if this Ruby wrapper goes out of memory.
    # @option opts [Integer] :io_threads The size of the 0MQ thread pool for this context.
    # @option opts [Integer] :max_sockets The maximum number of sockets allowed for this context.
    # @option opts [Boolean] :close_sockets If true (default), all open sockets will be closed when the context is terminated or garbage collected.
    def initialize(opts={})
      @ptr = API::invoke :zmq_ctx_new
      @sockets, @socket_mutex = [], Mutex.new

      self.io_threads = opts[:io_threads] if opts[:io_threads]
      self.max_sockets = opts[:max_sockets] if opts[:max_sockets]

      # Clean up if garbage collected
      @destroyer = self.class.finalize(@ptr, @sockets, @socket_mutex)
      ObjectSpace.define_finalizer self, @destroyer
    end

    # The memory pointer to the 0MQ context object. You shouldn't need
    # to use this directly unless you're doing low-level work outside of
    # the EZMQ interface.
    # @return [FFI::Pointer]
    # @raise [ContextClosed] if the context has already been destroyed
    def to_ptr
      @ptr or raise ContextClosed
    end

    # The size of the 0MQ thread pool for this context.
    def io_threads
      API::invoke :zmq_ctx_get, self, Options[:io_threads]
    end

    # Specifies the size of the 0MQ thread pool to handle I/O
    # operations. If your application is using only the inproc transport
    # for messaging you may set this to zero, otherwise set it to at
    # least one. This option only applies before creating any sockets
    # on the context.
    def io_threads=(val)
      API::invoke :zmq_ctx_set, self, Options[:io_threads], val
    end

    # Returns the maximum number of sockets allowed for this context.
    def max_sockets
      API::invoke :zmq_ctx_get, self, Options[:max_sockets]
    end

    # Sets the maximum number of sockets allowed on the context.
    def max_sockets=(val)
      API::invoke :zmq_ctx_set, self, Options[:max_sockets], val
    end


    # @private
    def <<(socket)
      socket_mutex.synchronize {sockets << socket}
    end

    # @private
    def remove(socket)
      socket_mutex.synchronize {sockets.delete(socket)}
    end



    # Closes any sockets and terminates the 0MQ context. Attempting to
    # access the context or any sockets after this will throw an exception.
    # @note This also occurs when the Context object is garbage collected.
    def terminate
      destroyer.call
      @ptr = nil
    end
    alias_method :destroy, :terminate
    alias_method :close, :terminate


    # Creates a routine that will safely close any sockets and terminate
    # the 0MQ context upon garbage collection.
    def self.finalize(ptr, sockets, socket_mutex)
      Proc.new do
        socket = nil
        while socket_mutex.synchronize {socket = sockets.shift}
          socket.close
        end
        API::invoke :zmq_ctx_destroy, ptr
      end
    end

  private
    attr_reader :destroyer, :socket_mutex


  end
end
