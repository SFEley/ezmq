module EZMQ
  # A {PUSH} socket is a send-only socket intended as the upstream
  # end of a pipeline. Messages are sent in round-robin order to
  # all connected sockets, and there is no receiving functionality.
  # @see {PULL}
  class PUSH < Socket
    include Sendable
  end
end
