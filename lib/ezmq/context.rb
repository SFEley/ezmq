require 'ezmq/api'

module EZMQ
  # A global 0MQ context that acts as the default container for all
  # sockets. The Context object is created lazily (i.e., only when it is
  # referenced for the first time) and safely for multiple threads.
  # Unless you have a good reason for multiple contexts you should be
  # using this placeholder, which will never be accidentally garbage
  # collected.
  def self.context
    @context or Thread.exclusive {@context ||= Context.new}
  end

  # Closes every socket on the global context and then removes the context
  # itself. The next attempt to reference EZMQ::context will create a new
  # context with no current sockets.
  # @note This method clears _only_ the global default context and its
  # sockets. Contexts you've created yourself and assigned to variables
  # are unaffected. (You can still close them with their own
  # Context#terminate calls.)
  def self.terminate!
    if @context
      @context.terminate
      @context = nil
    end
  end

  class Context

    # From include/zmq.h
    Options = {
      io_threads:   1,
      max_sockets:  2
    }.freeze

    attr_reader :sockets

    # Creates a new 0MQ context. Hooks are also established to terminate it
    # if this Ruby wrapper goes out of memory.
    # @option opts [Integer] :io_threads The size of the 0MQ thread pool for this context.
    # @option opts [Integer] :max_sockets The maximum number of sockets allowed for this context.
    def initialize(opts={})
      @ptr = API::invoke :zmq_ctx_new
      @sockets = []

      self.io_threads = opts[:io_threads] if opts[:io_threads]
      self.max_sockets = opts[:max_sockets] if opts[:max_sockets]

      # Clean up if garbage collected
      @destroyer = self.class.finalize(@ptr, @sockets)
      ObjectSpace.define_finalizer self, @destroyer
    end

    # The FFI memory pointer to the 0MQ context object. You shouldn't need
    # to use this directly unless you're doing low-level work outside of
    # the EZMQ interface.
    # @return [FFI::Pointer]
    # @raise [ContextClosed] if the context has already been destroyed
    def ptr
      @ptr or raise ContextClosed
    end

    # The FFI memory pointer to the 0MQ context object. Differs from the
    # #ptr method in that it returns a null pointer if the context has
    # been destroyed rather than throwing an exception. Enables API
    # functions to accept this object wherever a context pointer would
    # be needed.
    # @return [FFI::Pointer]
    def to_ptr
      ptr
    rescue ContextClosed
      Fiddle::NULL
    end

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


    # @private
    def <<(socket)
      sockets << socket
    end

    # @private
    def remove(socket)
      sockets.delete(socket)
    end



    # Closes any sockets and terminates the 0MQ context. Attempting to
    # access the context or any sockets after this will throw an exception.
    # @note This also occurs when the Context object is garbage collected.
    def terminate
      destroyer.call
      @ptr = nil
    end
    alias_method :destroy, :terminate


    # Creates a routine that will safely close any sockets and terminate
    # the 0MQ context upon garbage collection.
    def self.finalize(ptr, sockets)
      Proc.new do
        sockets.each &:close
        API::zmq_ctx_destroy(ptr)
      end
    end

  private
    attr_reader :destroyer


  end
end
