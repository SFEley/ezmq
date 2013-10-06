require 'ffi'

module EZMQ
  # The functions of the ZeroMQ C library are wrapped here. It's a direct
  # translation of `zmq_foo()` to `EZmq::API::zmq_foo`.  If you want to use
  # this module alone and ignore all of the Ruby objects from the rest
  # of the EZmq gem, knock yourself out. Just know your FFI pointers and
  # be careful with your setup and teardown.
  module API
    extend FFI::Library
    ffi_lib 'zmq'

    attach_function 'zmq_ctx_new', [], :pointer
    attach_function 'zmq_ctx_get', [:pointer, :int], :int
    attach_function 'zmq_ctx_set', [:pointer, :int, :int], :int
    attach_function 'zmq_ctx_destroy', [:pointer], :int

    attach_function 'zmq_strerror', [:int], :string

    # Wraps 0MQ's C-based calling semantics (return a 0 on success, -1 and
    # get the errno on failures) in a much more Rubyish "give me what I
    # asked for or throw an exception" style.
    # @param func [Symbol] Name of the 0MQ API function to call
    # @param *args [Array] Arguments passed directly to the 0MQ function
    def self.invoke(name, *args)
      result = self.send name, *args
      if result == -1
        raise ZMQError.for_errno(FFI.errno)
      else
        result
      end
    end


  end
end
