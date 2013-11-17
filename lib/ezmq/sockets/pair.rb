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

    # The list of local endpoints to which this socket is bound.
    # @see #bind
    attr_reader :endpoints

    # The list of remote endpoints to which this socket is connected.
    # @see #connect
    attr_reader :connections

    # Short name used for logging, routing, and inproc: bindings
    attr_reader :name

    # @!attribute [rw] backlog
    #   The maximum number of outstanding connections to this socket
    #   (for connection-oriented transports such as *tcp*). See your
    #   OS documentation for the *listen* function. Defaults to 100.
    socket_option :backlog

    # @!attribute [rw] linger
    #   The time in milliseconds that the socket will wait for pending
    #   messages to be handled upon closing. A value of 0 means that
    #   the socket will always close immediately, discarding pending
    #   messages. A value of -1 means that the socket will wait forever
    #   for messages to be delivered before closing. Defaults to the
    #   value of the class attribute if one is defined, or to `EZMQ.linger`
    #   if defined (1 second unless overridden), or to -1.
    socket_option :linger

    # @!attribute [r] rcvmore
    #   1 if the socket currently has more parts of a multi-part message
    #   waiting to be processed; 0 otherwise. The {#more?} method casts
    #   this to a boolean.
    get_option :rcvmore

    # @!attribute [rw] send_limit
    #   The high water mark for outbound messages. This is a hard limit on
    #   the maximum number of outstanding messages that can be queued for
    #   any single peer. Changes to this value will only take effect for
    #   *new* socket connections. Defaults to 1000.
    socket_option :sndhwm, :send_limit

    # @!attribute [rw] receive_limit
    #   The high water mark for inbound messages. This is a hard limit on
    #   the maximum number of received messages that can be queued from
    #   any single peer. Changes to this value will only take effect for
    #   *new* socket connections. Defaults to 1000.
    socket_option :rcvhwm, :receive_limit

    # @!attribute [rw] send_timeout
    #   If set to a positive value, send operations will time out with an {EAGAIN}
    #   exception after that many milliseconds if the message cannot be sent.
    #   If set to 0, the socket will always raise {EAGAIN} if the message
    #   cannot be sent immediately. If set to -1, the socket will block
    #   indefinitely until the message can be sent. Defaults to -1.
    socket_option :sndtimeo, :send_timeout

    # @!attribute [rw] receive_timeout
    #   If set to a positive value, receive operations will time out with an {EAGAIN}
    #   exception after that milliseconds if there are no messages to receive.
    #   If set to 0, the socket will always raise {EAGAIN} if there are no
    #   messages waiting. If set to -1, the socket will block indefinitely
    #   until a message is received. Default to -1.
    socket_option :rcvtimeo, :receive_timeout


    # The memory pointer to the 0MQ socket object. You shouldn't need
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
    # @return [API::Pointer]
    def to_ptr
      ptr
    rescue SocketClosed
      API::NULL
    end



    # Creates a new Socket wrapping a 0MQ socket structure. By default
    # this socket uses the global context (EZMQ::context) and does not
    # begin life bound to any interfaces or connected to any other 0MQ
    # sockets, but you can customize this with options.
    # @option opts [Context] :context The socket's 0MQ context; defaults to EZMQ::context
    # @option opts [String, Symbol, Array<String, Symbol>] :bind One or more endpoints or endpoint shortcuts for this socket to listen on (see {#bind})
    # @option opts [String, Array<String>] :connect One or more endpoints for this socket to connect to (see {#connect})
    # @option opts [String] :name Simple human name for this socket. Used in logging, listings, automatic _inproc_ bindings and routing identifiers
    def initialize(opts={})
      @endpoints, @connections = [], []
      @context = opts.fetch(:context) {EZMQ.context}
      @name = opts.fetch(:name) {nextname}

      @ptr = API::zmq_socket context, self.class
      context << self

      bind *opts[:bind] if opts[:bind]
      connect *opts[:connect] if opts[:connect]

      # Clean up if garbage collected
      @destroyer = self.class.finalize(@ptr)
      ObjectSpace.define_finalizer self, @destroyer

      # Set linger value
      if self.class.linger
        self.linger = self.class.linger
      elsif EZMQ.linger
        self.linger = EZMQ.linger
      end
    end

    # Binds the socket to begin listening on one or more local endpoints.
    # The endpoint is a URI with a different format for different protocols.
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
        API::invoke :zmq_bind, self, parse_for_binding(address)
        endpoints << last_endpoint
      end
      endpoints
    end

    # Connects the socket to one or more remote or local endpoints.
    # Non-*inproc* endpoints need not have a socket bound already.
    # See {#bind} for a deeper description of endpoint formats (but note
    # that the `:tcp`/`:ipc`/`:inproc` shortcuts are not valid for
    # connecting).
    #
    # If the bound end is a local socket in the same process, you can
    # pass the other {Socket} object itself rather than an endpoint string.
    # EZMQ will connect to the first *inproc* endpoint for that socket,
    # or bind it to a new one with an autogenerated name if no *inproc*
    # transports are specified.
    #
    # @note Creating a 0MQ socket connection does not guarantee that a
    # network link will happen immediately. 0MQ connects and
    # disconnects from the transport as needed when messages are sent or
    # polled for receiving. So a successful {#connect} call does not mean
    # that the connection is valid and can be established; you are
    # responsible for whatever handshakes you require to ensure that traffic
    # is flowing.
    #
    # @param *addresses [String, Socket, <String, Socket>] List of endpoints to connect to.
    # @return [Array] The list of this socket's connections.
    def connect(*addresses)
      addresses.each do |address|
        endpoint = parse_for_connecting(address)
        API::invoke :zmq_connect, self, endpoint
        connections << endpoint
      end
      connections
    end

    # Sends a single- or multi-part message on the socket. Messages can be
    # single strings, lists of strings, or {Message} objects. If you want to
    # delay sending until more parts can be delivered, use the `more: true`
    # option for all but the last part.
    #
    # If the message
    # can't be immediately queued -- no connections, the sending high-water
    # mark was reached, etc. -- the default behavior is to block until it
    # can be sent. You can alter this by either passing the `async: true`
    # option (which will raise a {ZMQError::EAGAIN} on a temporary send
    # failure) or by passing a block implementing your own behavior for
    # resending, logging the failure, or whatever else is appropriate. The
    # block will receive a {Message} containing all parts that have been
    # queued for the current send.
    #
    # @note We are well aware that this method name conflicts with the
    # basic Ruby {Object#send} for calling arbitrary methods. We are *not*
    # breaking that behavior; if the first argument to the method call is
    # a Symbol, we fall back to the inherited {Object#send}. Make sure
    # you're always sending strings or Messages to avoid accidental method
    # invocation.
    #
    # @param *parts [String, Array<String>, Message] The content to be delivered.
    # @param opts [Hash, optional] Options for additional parts or non-blocking.
    # @option opts [Boolean] :more If true, don't send immediately; wait for additional parts.
    # @option opts [Boolean] :async If true, raises {EAGAIN} or passes to the supplied block if the message can't be queued for sending immediately.
    # @yield Block invoked if the message can't be sent immediately. Implies `async: true`.
    # @yieldparam message [Message] Accumulated parts of the message that was delayed.
    # @return [Fixnum] The total number of bytes queued for sending.
    def send(*parts)
      return super if parts.first.is_a?(Symbol)

      if parts.last.respond_to?(:fetch)
        opts = parts.pop
      else
        opts = {}
      end

      while part = parts.shift
        size = part.bytesize
        content_ptr = API::Pointer.malloc(size)
        content_ptr[0, size] = part
        flags = 0
        flags += 1 if opts[:async]
        flags += 2 if !parts.empty? || opts[:more]
        API::invoke :zmq_send, self, content_ptr, size, flags
      end
    end

    # Sends the message content from a {MessageFrame} object, clearing its
    # contents after transmission. This is considered an advanced feature, making
    # use of the more complex `zmq_msg_send` API. Users who don't have
    # complex memory or routing requirements are encouraged to use the
    # {#send} method instead.
    # @param [MessageFrame] frame
    # @param [Hash, optional] opts
    # @option opts [Boolean] :more If true, don't send immediately; wait for additional parts.
    # @option opts [Boolean] :async If true, raises {EAGAIN} when a message temporarily can't be sent.
    # @return [Fixnum] The number of bytes sent from the frame.
    def send_from_frame(frame, opts={})
      flags = 0
      flags += 1 if opts[:async]
      flags += 2 if opts[:more]
      API::invoke :zmq_msg_send, frame, self, flags
    end


    # Receives a message from the socket. The return is a {Message} object
    # containing one or more parts, which duck types reasonably well to a
    # String or to an Array.
    #
    # If no message is immediately available, the default behavior is to
    # block until one arrives. You can assure a fast return by setting the
    # `async: true` option, which will raise a {ZMQError::EAGAIN} if no
    # message is available. (Event-driven callbacks are planned for a
    # future release.)
    #
    # @note By default, message parts are received using the 0MQ
    # `zmq_msg_recv` API, which allows content of any length but is
    # moderately complex and requires multiple Ruby steps to manage
    # memory structures.  If you know your message parts will never exceed
    # a certain length (or if you want to cap them on purpose to avoid
    # memory overruns) consider using the *:size* option, which will
    # trigger the simpler and marginally faster `zmq_recv` API. Message parts
    # larger than your stated *:size* in bytes will be truncated; parts
    # of that size or smaller will be unaffected.

    #
    # @param [Hash, optional] opts
    # @option opts [Boolean] :async If true, raises {EAGAIN} when a message is not yet available.
    # @option opts [Fixnum] :size If specified, each message part is captured in a fixed-size buffer and truncated at the given byte limit.
    # @return [Message]
    def receive(opts={})
      message = Message.new receive_part(opts)
      while more?
        message << receive_part(opts)
      end
      message
    end

    # Gets a single message part from the socket. There may or may not be
    # more parts after this one; use {#more?} to check.
    #
    # If no message is immediately available, the default behavior is to
    # block until one arrives. You can assure a fast return by setting the
    # `async: true` option, which will raise a {ZMQError::EAGAIN} if no
    # message is available. (Event-driven callbacks are planned for a
    # future release.)
    #
    # @note By default, message parts are received using the 0MQ
    # `zmq_msg_recv` API, which allows content of any length but is
    # moderately complex and requires multiple Ruby steps to manage
    # memory structures.  If you know your messages will never exceed
    # a certain length (or if you want to cap them on purpose to avoid
    # memory overruns) consider using the *:size* option, which will
    # trigger the simpler and marginally faster `zmq_recv` API. Messages
    # larger than your stated *:size* in bytes will be truncated; messages
    # of that size or smaller will be unaffected.
    #
    # @note If you fail to retrieve every part
    # of a message in progress, blocking or other strange things may happen.
    # Using this method makes you responsible for your own flow control.
    # Unless your use case or data sizes compel you to process parts
    # incrementally, it *usually* makes more sense to use the {#receive}
    # method to get all parts at once.
    #
    # @param [Hash, optional] opts
    # @option opts [Boolean] :async If true, raises {EAGAIN} when a message is not yet available.
    # @option opts [Fixnum] :size If specified, capture the part in a fixed-size buffer and truncate it at the given byte limit.
    # @return [String] Received message data with binary encoding.
    def receive_part(opts={})
      if size = opts[:size]
        ptr = API::Pointer.malloc size
        received_size = API::invoke :zmq_recv, self, ptr, size, 0
        ptr.to_s([size, received_size].min)
      else
        receive_into_frame(receive_frame, opts)
        receive_frame.to_s
      end
    end

    # Receives a message part into a {MessageFrame} object, clearing any
    # existing contents. This is considered an advanced feature, making
    # use of the more complex `zmq_msg_recv` API. Users who don't have
    # complex memory or routing requirements are encouraged to use the
    # {#receive} method instead.
    # @param [MessageFrame] frame
    # @param [Hash, optional] opts
    # @option opts [Boolean] :async (false) If true, raises {EAGAIN} when a message is not yet available.
    # @return [Fixnum] The number of bytes received into the frame.
    def receive_into_frame(frame, opts={})
      API::invoke :zmq_msg_recv, frame, self, (opts[:async] ? 1: 0)
    end


    # True if the socket currently has more parts of a multi-part message
    # waiting to be processed; otherwise false.
    def more?
      rcvmore == 1
    end

    # Returns the most recently bound address that this socket is listening
    # to from 0MQ.
    def last_endpoint
      val_pointer = API::Pointer.malloc(255)
      size_pointer = API::Pointer.malloc(Fiddle::SIZEOF_SIZE_T)
      size_pointer[0] = 255
      API::invoke :zmq_getsockopt, self, Options[:last_endpoint], val_pointer, size_pointer
      val_pointer.to_s(size_pointer[0].to_i - 1)
    end
    alias_method :endpoint, :last_endpoint

    # Closes this socket.
    def close
      destroyer.call
      @ptr = nil
    end

    # Creates a routine that will set a timeout period on a given socket
    # and then close it upon termination.
    def self.finalize(ptr)
      Proc.new do
        API::zmq_close ptr
      end
    end


  private
    attr_reader :destroyer

    def receive_frame
      @receive_frame ||= MessageFrame.new
    end

    def parse_for_binding(address)
      case address
      when :inproc then "inproc://#{name}"
      when :ipc then "ipc://*"
      when :tcp then "tcp://*:*"
      when %r[^(tcp|ipc|inproc|e?pgm)://.+] then address
      else raise InvalidEndpoint, address
      end
    end

    def parse_for_connecting(address)
      case address
      when Socket
        address.endpoints.detect {|e| e =~ /^inproc:/} or begin
          address.bind :inproc
          address.last_endpoint
        end
      when %r[^(tcp|ipc|inproc|e?pgm)://.+] then address
      else raise InvalidEndpoint, address
      end
    end

    def recv(size, async)
      ptr = API::Pointer.malloc size
      received_size = API::invoke :zmq_recv, self, ptr, size, 0
      ptr.to_s([size, received_size].min)
    end

  end
end
