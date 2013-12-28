module EZMQ

  # An {XPUB} socket behaves like a {PUB} socket but has limited
  # receiving functionality for the purpose of subscriptions. An {XPUB}
  # socket automatically handles subscription notices and selective
  # filtering for its own subscribers, but also keeps subscriptions in its
  # received message queue for handling with {#receive},
  # {#receive_into_frame}, or proxies and polling. This enables both
  # forwarding of subscriptions to upstream destinations and custom
  # monitoring or event handling upon new subscriptions or unsubscriptions.
  # See the {XSUB} documentation for the subscription message format.
  #
  # ### Duplicate Subscriptions
  # By default, duplicate subscription messages are silently dropped,
  # even from different subscriber sockets. A given subscription filter
  # will only ever be received once. This reduces message traffic for
  # upstream proxies but may pose problems for monitoring. To receive a
  # message on every subscription or unsubscription from every client,
  # set the {#verbose} attribute to _true._
  class XPUB < Socket
    include Sendable
    include Receivable

    # @!attribute [w] verbose
    #   Set to _true_ or 1 to receive all subscribe/unsubscribe messages
    #   including duplicates. Defaults to 0 (false), dropping duplicates.
    set_option :xpub_verbose, :verbose

  end
end
