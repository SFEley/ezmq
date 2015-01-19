require_relative '../socket/subscribable'

module EZMQ

  # A {SUB} socket is the receiving end of a publish/subscribe pattern.
  # It connects to one or more {PUB} sockets and uses its {#subscribe}
  # method to declare which messages it wants to receive. Messages are
  # then received in fair-queuing order. There is no sending functionality
  # for this socket type.
  # @see {PUB}
  class SUB < Socket
    include Receivable
    include Subscribable


    # @!method subscribe=(filter)
    #   @api private
    #   A low-level method that sets the ZMQ_SUBSCRIBE socket option.
    #   Using this directly will bypass the socket's {#subscriptions}
    #   tracking array.
    #   @param filter [String] String to use for binary prefix matching
    set_option :subscribe

    # @!method unsubscribe=(filter)
    #   @api private
    #   A low-level method that sets the ZMQ_UNSUBSCRIBE socket option.
    #   Using this directly will bypass the socket's {#subscriptions}
    #   tracking array.
    #   @param filter [String] String to remove from binary prefix tracking
    set_option :unsubscribe

    private 'subscribe=', 'unsubscribe='

  end
end
