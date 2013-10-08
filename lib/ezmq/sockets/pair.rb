require 'ezmq/socket'

module EZMQ
  # Wraps a 0MQ **PAIR** socket, which implements the "exclusive pair"
  # pattern. A socket of type PAIR can be connected to one other PAIR socket
  # at any one time. No message routing or filtering is performed.
  #
  # When a PAIR socket cannot send due to having reached the high water mark
  # for the connected peer, or if no peer is connected, then any `send`
  # operations will block until the peer becomes available for sending.
  # Messages are not discarded.
  #
  # @note PAIR sockets are designed for inter-thread communication using
  # the *inproc:* transport type and do not implement functionality such
  # as auto-reconnection. PAIR sockets are considered experimental and
  # may have other missing or broken aspects.
  # @see http://api.zeromq.org/3-2:zmq-socket
  #
  class PAIR
    attr_reader :context

    # Creates a new Socket wrapping a 0MQ socket structure. By default
    # this socket uses the global context (EZMQ::context) and does not
    # begin life bound to any interfaces or connected to any other 0MQ
    # sockets, but you can customize this with options.
    # @option opts [Context] :context The socket's 0MQ context; defaults to EZMQ::context
    # @option opts [String, Array<String>] :bind One or more addresses for this socket to listen on
    # @option opts [String, Array<String>] :connect One or more addresses for this socket to connect to
    def initialize(opts={})
      @context = opts.fetch(:context) {EZMQ.context}

    end
  end
end
