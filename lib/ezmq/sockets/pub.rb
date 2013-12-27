module EZMQ
  # A {PUB} socket is the sending end of a publish/subscribe pattern.
  # It connects to one or more {SUB} sockets and is aware of their
  # subscription preferences. Every message sent is delivered to every
  # {SUB} socket with a matching subscription. If a particular socket
  # is unable to receive due to high-water mark limits, the message is
  # dropped.  There is no receiving functionality for this socket type.
  # @see {SUB}
  class PUB < Socket
    include Sendable
  end
end
