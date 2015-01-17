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


    # A human identifier for this context. Only used for logging.
    attr_accessor :name
    alias_method :to_s, :name

    # The memory pointer to the 0MQ context object. You shouldn't need
    # to use this directly unless you're doing low-level work outside of
    # the EZMQ interface. Nil if the context has been closed or is not
    # yet initialized.
    attr_reader :ptr

    # Creates a new 0MQ context. Hooks are also established to terminate it
    # if this Ruby wrapper goes out of memory.
    # @option opts [Integer] :io_threads The size of the 0MQ thread pool for this context
    # @option opts [Integer] :max_sockets The maximum number of sockets allowed for this context
    # @option opts [Logger] :logger Object to receive logging messages (defaults to `EZMQ.logger`)
    # @option opts [String] :name Identifies this context for logging and socket ownership (defaults to 'Context-' plus an auto-incrementing number)
    def initialize(opts={})
      self.logger = opts.fetch(:logger) {EZMQ.logger}
      self.name = opts.fetch(:name) {nextname}

      @ptr = API::invoke :zmq_ctx_new
      info "New context created."

      @socket_list, @socket_mutex = [], Mutex.new

      self.io_threads = opts[:io_threads] if opts[:io_threads]
      self.max_sockets = opts[:max_sockets] if opts[:max_sockets]

      # Clean up if garbage collected
      @destroyer = self.class.finalize(ptr, socket_list)
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

    # The active sockets attached to this context. All sockets will be
    # closed when the context is terminated or goes out of scope.
    def sockets
      socket_mutex.synchronize do
        socket_list.delete_if {|socket| socket.closed?}
      end
    end

    # @private
    def <<(socket)
      socket_mutex.synchronize {socket_list << socket}
    end

    # Closes any sockets and terminates the 0MQ context. Attempting to
    # access the context or any sockets after this will throw an exception.
    # @note This also occurs when the Context object is garbage collected.
    def terminate
      destroyer.call
      @ptr = nil
      ObjectSpace.undefine_finalizer(self)
      info "Context destroyed."
    end
    alias_method :destroy, :terminate
    alias_method :close, :terminate

    # True if the context has been closed in 0mq.
    def closed?
      ptr.nil?
    end

    # Creates a routine that will safely close any sockets and terminate
    # the 0MQ context upon garbage collection.
    def self.finalize(ptr, sockets)
      Proc.new do
        API::invoke :zmq_ctx_shutdown, ptr
        sockets.each { |socket| socket.close }
        API::invoke :zmq_ctx_term, ptr
      end
    end

  private
    attr_reader :destroyer, :socket_list, :socket_mutex

    @@contextnum ||= 0

    def nextname
      "Context-#{@@contextnum += 1}"
    end

  end
end
