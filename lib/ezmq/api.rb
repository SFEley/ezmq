require 'fiddle/import'

module EZMQ
  # The functions of the ZeroMQ C library are wrapped here. It's a direct
  # translation of `zmq_foo()` to `EZmq::API::zmq_foo`.  If you want to use
  # this module alone and ignore all of the Ruby objects from the rest
  # of the EZmq gem, knock yourself out. Just know your FFI pointers and
  # be careful with your setup and teardown.
  module API
    extend Fiddle::Importer
    dlload 'libzmq.dylib'

    # Context functions
    extern 'void* zmq_ctx_new ()'
    extern 'int zmq_ctx_get (void*, int)'
    extern 'int zmq_ctx_set (void*, int, int)'
    extern 'int zmq_ctx_destroy (void*)'

    # Socket functions
    extern 'void* zmq_socket (void*, int)'
    extern 'int zmq_close(void*)'
    extern 'int zmq_bind (void*, const char*)'
    extern 'int zmq_connect (void*, const char*)'
    extern 'int zmq_getsockopt (void*, int, void*, size_t*)'
    extern 'int zmq_send (void*, void*, size_t, int)'
    extern 'int zmq_recv (void*, void*, size_t, int)'

    # Message functions
    extern 'int zmq_msg_init (zmq_msg_t*)'

    THING = import_symbol()


    # Info functions
    extern 'const char *zmq_strerror (int)'

    # Wraps 0MQ's C-based calling semantics (return a 0 on success, -1 or
    # null pointer and get the errno on failures) in a much more Rubyish
    # "give me what I asked for or throw an exception" style.
    #
    # @param func [Symbol] Name of the 0MQ API function to call
    # @param *args [Array] Arguments passed directly to the 0MQ function
    def self.invoke(name, *args)
      result = self.send name, *args
      case result
      when Fiddle::Pointer
        raise ZMQError.for_errno(Fiddle.last_error) if result.null?
        result
      when Fixnum
        raise ZMQError.for_errno(Fiddle.last_error) if result == -1
        result
      else
        result
      end
    end


  end
end
