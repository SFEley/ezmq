module EZMQ

  # A {SUB} socket is the receiving end of a publish/subscribe pattern.
  # It connects to one or more {PUB} sockets and uses its {#subscribe}
  # method to declare which messages it wants to receive. Messages are
  # then received in fair-queuing order. There is no sending functionality
  # for this socket type.
  # @see {PUB}
  class SUB < Socket
    include Receivable

    # The list of filters to which this socket is currently subscribed.
    attr_reader :subscriptions

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

    # Creates a new {SUB} socket and optionally subscribes it to one or more
    # filters.
    #
    # @note New sockets begin with no subscriptions, meaning they will
    # receive no messages from publishers. You _must_ create at least one
    # filter using the `:subscribe` option at initialization or the
    # {#subscribe} method in order to receive anything. Use
    # `:subscribe => ''` (the empty string) to receive all messages.
    #
    # @option (see Socket#initialize)
    # @option opts [String, Array<String>] :subscribe One or more filter strings to subscribe to. (Use `''` to subscribe to all messages.)
    def initialize(opts={})
      @subscriptions = []
      filters = opts.delete(:subscribe)  # Process these after the socket's set up
      super
      subscribe *filters if filters
    end

    # Creates one or more message filters to receive messages from
    # publishers. Each parameter must be a string representing the _start_
    # of a desired message. Connected {PUB} sockets will compare these
    # filters byte-for-byte with the start of each message sent; if at
    # least one filter matches, the message will be delivered to this socket.
    # For a multi-part message, only the first part will be compared.
    #
    # To subscribe to _all_ messages from all publishers, call {#subscribe}
    # with an empty string or with no parameters. Use the {#subscriptions}
    # method to list the current filters.
    # @param *filters [String] Any number of prefix strings
    # @return [Array<String>] The updated list of socket subscriptions
    def subscribe(*filters)
      filters << '' if filters.empty?
      filters.each do |filter|
        self.subscribe = filter
        self.subscriptions << filter
      end
    end

    # Removes one or more message filters, informing publishers to no longer
    # send matching messages. The strings provided _should_ exactly match
    # entries in the socket's {#subscriptions} list. (Unsubscribing a filter
    # that was never subscribed is not an error but is not useful.)
    # @param *filters [String] Any number of prefix strings
    # @return [Array<String>] The updated list of socket subscriptions
    def unsubscribe(*filters)
      filters.each do |filter|
        self.unsubscribe = filter
        self.subscriptions.delete(filter)
      end
    end



  end
end
