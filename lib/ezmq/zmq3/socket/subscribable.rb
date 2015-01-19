module EZMQ
  class Socket

    # @api private
    # High-level methods for subscribing and unsubscribing from message
    # filters. These are made abstract because {SUB} and {XPUB} have
    # different mechanisms for subscribing. The enclosing class must
    # implement {#subscribe=} and {#unsubscribe=} methods.
    module Subscribable
      # The list of filters to which this socket is currently subscribed.
      attr_reader :subscriptions

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
          info "Subscribed to '#{filter}'"
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
          info "Unsubscribed from '#{filter}'"
        end
      end


    end
  end
end
