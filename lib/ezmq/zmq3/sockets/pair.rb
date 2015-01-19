require_relative '../socket'

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
  class PAIR < Socket
    include Sendable
    include Receivable

    # Returns a two-element array of {PAIR} sockets that are already
    # connected via _inproc_ transport.  The `:name`, `:bind` and `:connect`
    # options are ignored; all other options are applied to both sockets on
    # initialization.
    #
    # @option opts [String] :left Name of the first socket (and also the _inproc_ binding)
    # @option opts [String] :right Name of the second socket
    #
    # @example
    #   left, right = EZMQ::PAIR.new_pair
    #   left.send "Mr. Watson, come here. I want to see you."
    #   right.receive   # => "Mr. Watson, come here. I want to see you."
    def self.new_pair(opts={})
      leftopts = opts.reject {|k, v| [:name, :bind, :connect, :left, :right].include?(k)}
      rightopts = leftopts.dup

      leftopts[:name] = opts[:left] if opts[:left]
      rightopts[:name] = opts[:right] if opts[:right]

      left, right = new(leftopts), new(rightopts)
      left.bind :inproc
      right.connect left.last_endpoint
      [left, right]
    end
  end
end
