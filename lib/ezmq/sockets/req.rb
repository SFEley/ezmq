require 'ezmq/socket'

module EZMQ
  # A **REQ** socket is the originating end of a request/reply pattern.
  # It sends and receives messages in alternating succession; attempting
  # to send two messages in a row or receive a message without sending one
  # will result in an {EFSM} exception.  (For *Finite State Machine*,
  # not *Flying Spaghetti Monster*.)
  #
  # REQ sockets can make valid connections to any number of {REP} and
  # {ROUTER} sockets. Messages will be distributed in a round-robin
  # pattern to all active connections. The standard {#send} and {#receive}
  # methods are of course supported, as well as a synchronous {#request}
  # method for convenience. The {#request} method sends one or more
  # message parts, blocks until a reply is received, and returns the
  # reply.
  class REQ < Socket


  end
end
