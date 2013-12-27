module EZMQ
  # A {PULL} socket is a receive-only socket intended as the downstream
  # end of a pipeline. Messages are received in fair-queueing order from
  # all connected sockets, and there is no sending functionality.
  # @see {PUSH}
  class PULL < Socket
    include Receivable
  end
end
