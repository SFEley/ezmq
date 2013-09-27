require 'ezmq/api'

module EZmq
  class Context
    attr_reader :ptr

    def initialize
      @ptr = API::zmq_ctx_new
    end

    def destroy
      API::zmq_ctx_destroy(ptr)
    end

  end
end
