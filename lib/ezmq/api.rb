require 'ffi'

module EZmq
  # The functions of the ZeroMQ C library are wrapped here. It's a direct
  # translation of `zmq_foo()` to `EZmq::API::zmq_foo`.  If you want to use
  # this module alone and ignore all of the Ruby objects from the rest
  # of the EZmq gem, knock yourself out. Just know your FFI pointers and
  # be careful with your setup and teardown.
  module API
    extend FFI::Library
    ffi_lib 'zmq'

    attach_function 'zmq_ctx_new', [], :pointer
  end
end
