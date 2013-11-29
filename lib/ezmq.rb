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
  end
  self.linger = 1000
end

require 'ezmq/api'
require 'ezmq/exceptions'
require 'ezmq/context'
require 'ezmq/sockets'
