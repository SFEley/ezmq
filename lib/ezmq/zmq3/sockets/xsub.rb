require_relative '../socket'
require_relative '../socket/subscribable'

module EZMQ
  # An {XSUB} socket behaves like the {SUB} socket but has limited
  # sending functionality for the purpose of subscriptions.
  # Rather than setting a socket option to add or remove a message filter,
  # {XSUB} sockets send specially formatted messages upstream. This allows
  # subscriptions to be monitored, forwarded, or proxied in conjunction
  # with {XPUB} sockets.
  #
  # The same {#subscribe} and {#unsubscribe} interface is implemented as
  # the {SUB} socket; you can substitute an {XSUB} socket in place with no
  # changes. If you wish to create your own subscription messages, you can
  # do so with the standard {#send} method.
  # @see SUB
  #
  # ### Subscription Messages
  # {XSUB} subscriptions and unsubscriptions must be single-part messages
  # conforming to the following rules:
  #
  # * A first byte of `\x01` (binary 1) indicates a subscription.
  # * A first byte of `\x00` (binary 0) indicates an unsubscription.
  # * The remaining bytes contain the filter content to be matched against.
  class XSUB < Socket
    include Receivable
    include Sendable
    include Subscribable

  private
    # @api private
    def subscribe=(filter)
      send "\x01#{filter}"
    end

    # @api private
    def unsubscribe=(filter)
      send "\x00#{filter}"
    end

  end
end
