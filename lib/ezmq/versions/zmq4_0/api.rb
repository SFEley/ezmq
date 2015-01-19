require 'ezmq/api'

module EZMQ
  module API

    # Changes between 0mq 3.2.x and 4.0.x. Because {EZMQ::API} is itself
    # a module, this must be added by extending rather than including.
    module Zmq4_0
      def self.extended(target)
        target.attach_function :zmq_ctx_term, [:pointer], :int, :blocking => true
        target.attach_function :zmq_ctx_shutdown, [:pointer], :int
      end
    end
  end
end
