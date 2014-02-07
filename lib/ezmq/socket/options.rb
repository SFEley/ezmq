module EZMQ
  class Socket

    # From include/zmq.h
    # Value arrays consist of the ZeroMQ option number, the type, and
    # an optional size for strings.
    Options = {
      affinity:                 [4, :uint64],
      identity:                 [5, :char, 255],
      subscribe:                [6, :char, 1024],
      unsubscribe:              [7, :char, 1024],
      rate:                     [8, :int],
      recovery_ivl:             [9, :int],
      sndbuf:                   [11, :int],
      rcvbuf:                   [12, :int],
      rcvmore:                  [13, :int],
      fd:                       [14, :int],
      events:                   [15, :int],
      type:                     [16, :int],
      linger:                   [17, :int],
      reconnect_ivl:            [18, :int],
      backlog:                  [19, :int],
      reconnect_ivl_max:        [21, :int],
      maxmsgsize:               [22, :int64],
      sndhwm:                   [23, :int],
      rcvhwm:                   [24, :int],
      multicast_hops:           [25, :int],
      rcvtimeo:                 [27, :int],
      sndtimeo:                 [28, :int],
      ipv4only:                 [31, :int],
      last_endpoint:            [32, :char, 1024],
      router_mandatory:         [33, :int],
      fail_unroutable:          [33, :int],   # Deprecated alias
      router_behavior:          [33, :int],  # Deprecated alias
      tcp_keepalive:            [34, :int],
      tcp_keepalive_cnt:        [35, :int],
      tcp_keepalive_idle:       [36, :int],
      tcp_keepalive_intvl:      [37, :int],
      tcp_accept_filter:        [38, :char, 1024],
      delay_attach_on_connect:  [39, :int],
      xpub_verbose:             [40, :int]
    }

    # @api private
    # Sets up a retrievable socket option as a reader attribute.
    def self.get_option(name, *aliases)
      option, type, limit = *Options[name]
      limit ||= 1   # Only :char has length limits
      define_method name do
        val_pointer = FFI::MemoryPointer.new(type, limit, true)
        size_pointer = FFI::MemoryPointer.new(:ssize_t)
        size_pointer.write_int(val_pointer.size)
        API::invoke :zmq_getsockopt, self, option, val_pointer, size_pointer
        value = case type
          when :int then val_pointer.read_int
          when :char then val_pointer.read_string(size_pointer.read_int).chomp("\x00")
          when :int64 then val_pointer.read_int64
          when :uint64 then val_pointer.read_uint64
        end
        val_pointer.free
        size_pointer.free
        value
      end
      aliases.each {|a| alias_method a, name}
    end

    # @api private
    # Sets up a settable socket option as a writer attribute.
    def self.set_option(name, *aliases)
      option, type = *Options[name]
      define_method "#{name}=".to_sym do |val|
        if val == true
          val = 1
        elsif val == false
          val = 0
        end

        case type
        when :int
          val_pointer = FFI::MemoryPointer.new(:int)
          val_pointer.write_int(val)
        when :char
          val_pointer = API.pointer_from(val)
        when :int64
          val_pointer = FFI::MemoryPointer.new(:int64)
          val_pointer.write_int64(val)
        when :uint64
          val_pointer = FFI::MemoryPointer.new(:uint64)
          val_pointer.write_uint64(val)
        end
        API::invoke :zmq_setsockopt, self, option, val_pointer, val_pointer.size
        debug "Option '#{name}' set to #{val}"
        val_pointer.free
        val
      end
      aliases.each {|a| alias_method "#{a}=".to_sym, "#{name}=".to_sym}
    end

    # @api private
    # Establishes reader and writer methods for socket options, as well as
    # for any aliases they might travel under.
    def self.socket_option(name, *aliases)
      get_option(name, *aliases)
      set_option(name, *aliases)
    end

    # @!attribute [r] last_endpoint
    #   The most recently bound address that this socket was connected to.
    get_option :last_endpoint, :endpoint

    # @!attribute [rw] identity
    #   Identifies this socket to {ROUTER} sockets for addressing purposes.
    #   If set, this value should be unique across all sockets that may
    #   possibly connect to the same {ROUTER}.
    socket_option :identity

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
    #   value of `EZMQ.linger` if defined (1 second unless overridden),
    #   or to -1.
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


  end
end
