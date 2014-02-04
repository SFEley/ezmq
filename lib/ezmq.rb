require 'ezmq/api'
require 'ezmq/exceptions'
require 'ezmq/context'
require 'ezmq/sockets'

module EZMQ
  class << self
    # The default `ZMQ_LINGER` socket value. Any sockets that do not set a
    # different value for their *linger* attribute on the socket or its class
    # will inherit this one upon creation.
    #
    # **IMPORTANT:** EZMQ sets this global default to 1000 milliseconds,
    # ensuring that 0MQ will not hang more than one second upon exit
    # even if there are pending messages. Set `EZMQ.linger = nil` to clear
    # the global default and fall back to 0MQ's default of -1, meaning
    # that closing a socket or context will potentially hang forever if
    # messages cannot be delivered.  (Danger Will Robinson!)
    # @see Socket#linger
    attr_accessor :linger

    # A ZeroMQ convenience method for joining two sockets with
    # optional tracing. The {Proxy} must be supplied with two sockets,
    # the _frontend_ and the _backend_, on initialization. Messages
    # received by either socket are immediately sent to the other.
    # (By convention, the pairing is chosen such that messages flow into
    # the frontend and out of the backend, but the proxy is symmetric and
    # the order does not matter for technical purposes.)
    #
    # A third _capture_ socket can optionally be supplied, turning the
    # proxy into a T-shaped splitter. Messages received from both the
    # frontend _and_ the backend will be sent to the capture socket if one
    # is given.
    #
    # @note The proxy is implemented in the ZeroMQ C library and is meant to
    # run indefinitely. Once called, this method will not return until the
    # context for the frontend and/or backend socket is terminated --
    # usually when the application exits. So unless you're calling this in
    # a simple script with no other logic, this method should be run in its
    # own thread.
    #
    # @param frontend [Socket] The first member of the bidirectional link.
    # @param backend [Socket] The second member of the bidirectional link.
    # @param capture [Socket] Optional socket that receives messages
    def proxy(frontend, backend, capture=nil)
      API::invoke :zmq_proxy, frontend, backend, capture

    end

  end
  self.linger = 1000
end
