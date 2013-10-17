require 'ezmq/socket'

module EZMQ
  # Wraps a 0MQ **PAIR** socket, which implements the "exclusive pair"
  # pattern. A socket of type PAIR can be connected to one other PAIR socket
  # at any one time. No message routing or filtering is performed.
  #
  # When a PAIR socket cannot send due to having reached the high water mark
  # for the connected peer, or if no peer is connected, then any `send`
  # operations will block until the peer becomes available for sending.
  # Messages are not discarded.
  #
  # @note PAIR sockets are designed for inter-thread communication using
  # the *inproc:* transport type and do not implement functionality such
  # as auto-reconnection. PAIR sockets are considered experimental and
  # may have other missing or broken aspects.
  # @see http://api.zeromq.org/3-2:zmq-socket
  #
  class PAIR < Socket
    # The parent context in which this socket was created. Defaults to
    # the global EXMQ::context for the application.
    attr_reader :context

    # The list of endpoints to which this socket is bound.
    attr_reader :endpoints


    # The FFI memory pointer to the 0MQ socket object. You shouldn't need
    # to use this directly unless you're doing low-level work outside of
    # the EZMQ interface.
    # @raise [SocketClosed] if the socket has already been destroyed
    def ptr
      @ptr or raise SocketClosed
    end

    # The FFI memory pointer to the 0MQ socket object. Differs from the
    # #ptr method in that it returns a null pointer if the socket has
    # been destroyed rather than throwing an exception. Enables API
    # functions to accept this object wherever a socket pointer would
    # be needed.
    # @return [FFI::Pointer]
    def to_ptr
      ptr
    rescue SocketClosed
      FFI::Pointer::NULL
    end



    # Creates a new Socket wrapping a 0MQ socket structure. By default
    # this socket uses the global context (EZMQ::context) and does not
    # begin life bound to any interfaces or connected to any other 0MQ
    # sockets, but you can customize this with options.
    # @option opts [Context] :context The socket's 0MQ context; defaults to EZMQ::context
    # @option opts [String, Array<String>] :bind One or more addresses for this socket to listen on
    # @option opts [String, Array<String>] :connect One or more addresses for this socket to connect to
    def initialize(opts={})
      @endpoints = []
      @context = opts.fetch(:context) {EZMQ.context}
      @ptr = API::zmq_socket context, self.class
      context << self
    end

    # Binds the socket to begin listening on one or more specific addresses.
    # The address is a URI with a different format for different protocols.
    # EZMQ can recognize and handle the following binding patterns:
    #
    # * **:inproc** - Creates an *inproc* transport using the socket's name
    #   (e.g. "inproc://PUB01")
    # * **:ipc** - Creates an *ipc* (Unix domain socket) transport with a
    #   random temporary pathname (equivalent to "ipc://*")
    # * **:tcp** - Creates a *tcp* transport that listens to all interfaces
    #   on a randomly assigned ephemeral port (equivalent to "tcp://\*:\*")
    # * **'inproc://_name_'** - Creates an *inproc* transport with the given
    #   _name_ (which must be unique within the context)
    # * **'ipc://_path_'** - Creates an *ipc* (Unix domain socket) transport
    #   at the given filesystem _path_ (which must have sufficient user
    #   privileges)
    # * **'tcp://_xx.xx.xx.xx_:_yyyy_'** - Creates a *tcp* transport that
    #   listens on the given local network interface and port.
    # * **'tcp://\*:_yyyy_'** - Creates a *tcp* transport that listens on
    #   all available network interfaces on the given port.
    # * **'tcp://_xx.xx.xx.xx_:\*'** - Creates a *tcp* transport that
    #   listens on the given local network interface with a system-assigned
    #   random port.
    # * **'pgm://_xx.xx.xx.xx_;_yy.yy.yy.yy_:_zzzz_'** - Creates a *pgm*
    #   multicast transport. The _xx_ address is the local interface; the
    #   _yy_ address is the multicast address, and _zzzz_ is the multicast
    #   port. (*Note:* Only PUB and SUB sockets support this transport.)
    # * **'epgm://_xx.xx.xx.xx_;_yy.yy.yy.yy_:_zzzz'** - Creates an *epgm*
    #   (PGM over UDP) multicast transport. The _xx_ address is the local
    #   interface; the _yy_ address is the multicast address, and _zzzz_
    #   is the multicast port. (*Note:* Only PUB and SUB sockets support
    #   this transport.)
    #
    # In every case, the canonical endpoint will be retrieved from 0MQ and
    # given in both the method return and the #endpoints list.
    #
    # @param *addresses [Symbol, String] List of patterns to bind to.
    # @return [Array] The updated list of endpoints as confirmed with 0MQ.
    def bind(*addresses)
      addresses.each do |address|
        API::invoke :zmq_bind, self, parse_address(address)
        endpoints << last_endpoint
      end
      endpoints
    end

    # Returns the most recently bound address that this socket is listening
    # to from 0MQ.
    def last_endpoint
      val_pointer = FFI::MemoryPointer.new(255)
      size_pointer = FFI::MemoryPointer.new(:size_t)
      size_pointer.write_int(255)
      API::invoke :zmq_getsockopt, self, Options[:last_endpoint], val_pointer, size_pointer
      val_pointer.read_string
    end

  private
    def parse_address(address)
      case address
      when :inproc then "inproc://#{name}"
      when :ipc then "ipc://*"
      when :tcp then "tcp://*:*"
      else address
      end
    end
  end
end
