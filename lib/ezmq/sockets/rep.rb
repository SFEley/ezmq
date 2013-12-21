require 'ezmq/socket'

module EZMQ
  # A **REP** socket is the answering end of a request/reply pattern.
  # It receives and sends messages in alternating succession; attempting
  # to receive two messages in a row or send a message without receiving one
  # will result in an {EFSM} exception.  (For *Finite State Machine*,
  # not *Flying Spaghetti Monster*.)
  #
  # REQ sockets can make valid connections to any number of {REQ} and
  # {DEALER} sockets. Messages are received from all active connections
  # in a fair queueing pattern, and sent messages are routed to the socket
  # from which the last message was received. The standard {#send}
  # and {#receive} methods are of course supported, as well as a
  # pseudo-event-driven {#on_request} method. The {#on_request} handler
  # blocks while it waits for a message to be received, feeds it to the
  # supplied proc or code block, and then sends the return value as
  # the reply.  It only does this once per invocation, so you'll likely
  # want to wrap it in a *while* or *until* loop with conditions to tell
  # it when to stop.
  class REP < Socket

    # Waits for a message to be received, passes it to the given block,
    # and sends the block's return value as the response.  The block should
    # return a single string, an array of strings (message parts), or a
    # {Message} object.
    # @yield [Message] A single- or multi-part message
    # @yieldreturn [String, Array, Message] Sent back to the requester
    def on_request
      request = receive
      response = yield request
      send *response
    end
  end
end
