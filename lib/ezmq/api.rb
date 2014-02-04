require 'ffi'

module EZMQ
  # The functions of the ZeroMQ C library are wrapped here. It's a direct
  # translation of `zmq_foo()` to `EZmq::API::zmq_foo`.  If you want to use
  # this module alone and ignore all of the Ruby objects from the rest
  # of the EZmq gem, knock yourself out. Just know your FFI pointers and
  # be careful with your setup and teardown.
  module API
    extend FFI::Library

    ffi_lib ['zmq', 'libzmq.so.3']

    # Context functions
    attach_function :zmq_ctx_new, [], :pointer
    attach_function :zmq_ctx_get, [:pointer, :int], :int
    attach_function :zmq_ctx_set, [:pointer, :int, :int], :int
    attach_function :zmq_ctx_destroy, [:pointer], :int, :blocking => true

    # Socket functions
    attach_function :zmq_socket, [:pointer, :int], :pointer
    attach_function :zmq_close, [:pointer], :int, :blocking => true
    attach_function :zmq_bind, [:pointer, :string], :int
    attach_function :zmq_connect, [:pointer, :string], :int
    attach_function :zmq_getsockopt, [:pointer, :int, :pointer, :pointer], :int
    attach_function :zmq_setsockopt, [:pointer, :int, :pointer, :size_t], :int
    attach_function :zmq_send, [:pointer, :pointer, :size_t, :int], :int, :blocking => true
    attach_function :zmq_recv, [:pointer, :pointer, :size_t, :int], :int, :blocking => true

    # Message functions
    attach_function :zmq_msg_init, [:pointer], :int
    attach_function :zmq_msg_init_size, [:pointer, :size_t], :int
    attach_function :zmq_msg_size, [:pointer], :size_t
    attach_function :zmq_msg_data, [:pointer], :pointer
    attach_function :zmq_msg_recv, [:pointer, :pointer, :int], :int, :blocking => true
    attach_function :zmq_msg_send, [:pointer, :pointer, :int], :int, :blocking => true
    attach_function :zmq_msg_copy, [:pointer, :pointer], :int
    attach_function :zmq_msg_move, [:pointer, :pointer], :int
    attach_function :zmq_msg_more, [:pointer], :int
    attach_function :zmq_msg_close, [:pointer], :int

    # Miscellaneous functions
    attach_function :zmq_proxy, [:pointer, :pointer, :pointer], :int, :blocking => true
    attach_function :zmq_strerror, [:int], :string

    # Wraps 0MQ's C-based calling semantics (return a 0 on success, -1 or
    # null pointer and get the errno on failures) in a much more Rubyish
    # "give me what I asked for or throw an exception" style.
    #
    # @param func [Symbol] Name of the 0MQ API function to call
    # @param *args [Array] Arguments passed directly to the 0MQ function
    def self.invoke(name, *args)
      result = self.send name, *args
      case result
      when FFI::Pointer
        raise ZMQError.for_errno(FFI.errno) if result.null?
        result
      when Fixnum
        raise ZMQError.for_errno(FFI.errno) if result == -1
        result
      else
        result
      end
    end

    # @api private
    # Convenience method to convert a string into an FFI pointer with no
    # null terminator.
    def self.pointer_from(val)
      size = val.bytesize
      ptr = FFI::MemoryPointer.new :char, val.bytesize
      ptr.put_bytes 0, val, 0, size
    end



  end
end
