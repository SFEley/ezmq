require_relative '../zmq3/api'

module EZMQ
  module API
    attach_function :zmq_ctx_term, [:pointer], :int, :blocking => true
    attach_function :zmq_ctx_shutdown, [:pointer], :int
  end
end
