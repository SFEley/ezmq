require 'ffi'

module EZMQ
  # The functions of the ZeroMQ C library are wrapped here. It's a direct
  # translation of `zmq_foo()` to `EZMQ::API::zmq_foo`.  If you want to use
  # this module alone and ignore all of the Ruby objects from the rest
  # of the EZmq gem, knock yourself out. Just know your FFI pointers and
  # be careful with your setup and teardown.
  #
  # @note EZMQ defaults to loading the most recent version of the *libzmq*
  #   library it can find in your system's shared library path. To force a
  #   specific library to be loaded, set the `ZMQ_LIB` environment variable
  #   to the name or path of the library you want (e.g. `libzmq.so.3`.)
  #   This must be set _before_ the EZMQ module is required, because
  #   library loading and version checking happens almost immediately.
  module API
    extend FFI::Library

    # Look for libzmq library in order of precedence
    ffi_lib [
      ENV['ZMQ_LIB'],
      'zmq',
      'libzmq.so.4',
      'libzmq.4.dylib',
      'libzmq.so.3',
      'libzmq.3.dylib'
    ]

    # All other APIs are referenced in zmq3/api.rb and forward.
    # Here we only grab the one we need for version check.
    attach_function :zmq_version, [:pointer, :pointer, :pointer], :void
  end
end
