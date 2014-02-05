require 'ezmq/loggable'
require 'ezmq/message'
require 'ezmq/message_frame'

require 'ezmq/socket/options'
require 'ezmq/socket/types'
require 'ezmq/socket/receivable'
require 'ezmq/socket/sendable'

module EZMQ

  # The abstract base class for all 0MQ socket types. All common behavior
  # for creating, configuring, binding and connecting sockets lives in
  # this class.
  class Socket
    include Loggable


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
    attr_accessor :name


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
    # @return [FFI::Pointer]
    def to_ptr
      ptr
    rescue SocketClosed
      FFI::Pointer::NULL
    end



    # Creates a new Socket wrapping a 0MQ socket structure. By default
    # this socket uses the global context ({EZMQ.context}) and does not
    # begin life bound to any interfaces or connected to any other 0MQ
    # sockets, but you can customize this with options.
    # @option opts [Context] :context The socket's 0MQ context; defaults to EZMQ::context
    # @option opts [String, Symbol, Array<String, Symbol>] :bind One or more endpoints or endpoint shortcuts for this socket to listen on (see {#bind})
    # @option opts [String, Array<String>] :connect One or more endpoints for this socket to connect to (see {#connect})
    # @option opts [Logger] :logger Object to receive logging messages (defaults to `EZMQ.logger`)
    # @option opts [String] :name Simple human name for this socket. Used in logging, listings, automatic _inproc_ bindings and routing identifiers
    def initialize(opts={})
      self.logger = opts.fetch(:logger) {EZMQ.logger}
      self.name = opts.fetch(:name) {nextname}

      @endpoints, @connections = [], []

      @context = opts.fetch(:context) {EZMQ.context}
      @ptr = API::invoke :zmq_socket, context, self.class
      context << self
      info "Socket created on #{context}."

      # Clean up if garbage collected
      @destroyer = self.class.finalize(@ptr)
      ObjectSpace.define_finalizer self, @destroyer

      # Set other options
      opts.each do |key, value|
        method = "#{key}=".to_sym
        __send__ method, value if respond_to?(method)
      end

      # Set linger value if global and our options didn't give one
      self.linger = EZMQ.linger unless opts.has_key?(:linger) || EZMQ.linger.nil?

      # Finally, bind or connect as appropriate
      bind *opts[:bind] if opts[:bind]
      connect *opts[:connect] if opts[:connect]
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
        info do
          if address == last_endpoint
            "Bound to #{address}"
          else
            "Bound to '#{address}' as #{last_endpoint}"
          end
        end
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
        info "Connected to #{endpoint}"
      end
      connections
    end

    # Closes this socket.
    def close
      destroyer.call
      context.remove self
      @ptr = nil
      info "Socket closed."
    end

    # Creates a routine that will set a timeout period on a given socket
    # and then close it upon termination.
    def self.finalize(ptr)
      Proc.new do
        API::invoke :zmq_close, ptr
      end
    end

  private
    attr_reader :destroyer

    # Simple counter to ensure sockets are distinguishable
    @@socketnum ||= 0

    def nextname
      "#{type}-#{@@socketnum += 1}"
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

  end
end
