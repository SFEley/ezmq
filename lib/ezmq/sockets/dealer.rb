module EZMQ
  # The {DEALER} is the least specialized of all socket types. It is
  # capable of both sending and receiving messages. Received messages
  # are handled in fair-queued order from all connected sockets. Sent
  # messages are delivered in round-robin order to any single connected
  # socket. No automatic inspection or modification of messages parts is
  # performed.
  #
  # The primary use case for this socket is forwarding messages from
  # other socket types, often in conjunction with a {ROUTER} socket to
  # retain origin information. This combination is commonly used as a
  # bridging proxy across networks or transport types. {DEALER} sockets
  # can also be used for monitoring or flow control in pipelining patterns.
  class DEALER < Socket
    include Receivable
    include Sendable
  end
end
