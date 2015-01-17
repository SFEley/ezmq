require 'ezmq/loggable'
require 'ezmq/api'
require 'ezmq/exceptions'
require 'ezmq/context'
require 'ezmq/sockets'

module EZMQ
  class << self
    # The version of the 0MQ library. Not to be confused with the version
    # of the EZMQ gem.
    # @return [String]
    def zmq_version
      pointers = []
      3.times {pointers << FFI::MemoryPointer.new(:int)}
      API::invoke :zmq_version, *pointers
      nums = pointers.collect {|p| p.read_int}
      pointers.each {|p| p.free}
      nums.join '.'
    end


    # The default `ZMQ_LINGER` socket value. Any sockets that do not set a
    # different value for their *linger* attribute on the socket or its class
    # will inherit this one upon creation.
    #
    # **IMPORTANT:** EZMQ sets this global default to 1000 milliseconds,
    # ensuring that 0MQ will not hang more than one second upon exit
    # even if there are pending messages. Set `EZMQ.linger = nil` to clear
    # the global default and fall back to 0MQ's default of -1, meaning
    # that closing a socket or context will potentially hang forever if
    # messages cannot be delivered.  (Danger Will Robinson!)
    # @see Socket#linger
    attr_accessor :linger


    # A global 0MQ context that acts as the default container for all
    # sockets. The Context object is created when it is referenced for the
    # first time. Unless you have a good reason for multiple contexts you
    # should be using this placeholder, which will never be accidentally
    # garbage collected.
    def context
      global_mutex.synchronize do
        if @context.nil? || @context.closed?
          @context = Context.new
        else
          @context
        end
      end
    end

    # Closes every socket on the global context and then removes the context
    # itself. The next attempt to reference {EZMQ.context} will create a new
    # context with no current sockets.
    # @note This method clears _only_ the global default context and its
    # sockets. Contexts you've created yourself and assigned to variables
    # are unaffected. (You can still close them with their own
    # {Context#terminate} calls.)
    def terminate!
      this_context = nil
      global_mutex.synchronize do
        this_context = @context
        @context = nil
      end
      this_context.terminate if this_context && this_context.closed?
    end

    # A ZeroMQ convenience method for joining two sockets with
    # optional tracing. The {Proxy} must be supplied with two sockets,
    # the _frontend_ and the _backend_, on initialization. Messages
    # received by either socket are immediately sent to the other.
    # (By convention, the pairing is chosen such that messages flow into
    # the frontend and out of the backend, but the proxy is symmetric and
    # the order does not matter for technical purposes.)
    #
    # A third _capture_ socket can optionally be supplied, turning the
    # proxy into a T-shaped splitter. Messages received from both the
    # frontend _and_ the backend will be sent to the capture socket if one
    # is given.
    #
    # @note The proxy is implemented in the ZeroMQ C library and is meant to
    # run indefinitely. Once called, this method will not return until the
    # context for the frontend and/or backend socket is terminated --
    # usually when the application exits. So unless you're calling this in
    # a simple script with no other logic, this method should be run in its
    # own thread.
    #
    # @param frontend [Socket] The first member of the bidirectional link.
    # @param backend [Socket] The second member of the bidirectional link.
    # @param capture [Socket] Optional socket that receives messages
    def proxy(frontend, backend, capture=nil)
      API::invoke :zmq_proxy, frontend, backend, capture
    # rescue EZMQ::ETERM
    rescue EZMQ::ENOTSOCK
    end
  private
    attr_reader :global_mutex

  end
  self.linger = 1000
  @global_mutex = Mutex.new

end
