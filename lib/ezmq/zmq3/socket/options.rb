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

    # From include/zmq.h
    # The ZMQ_EVENTS option concatenates these values to signal readiness
    # for reading or writing:

    # The socket can receive a message without blocking.
    POLLIN = 0b001

    # The socket can send a message without blocking.
    POLLOUT = 0b010

    # Error on standard socket monitored by **zmq_poll** (rarely used)
    POLLERR = 0b100


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

        if val.nil?     # Pass a null pointer on nil regardless of type
          API::invoke :zmq_setsockopt, self, option, FFI::Pointer::NULL, 0
        else
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
          val_pointer.free
        end
        debug "Option '#{name}' set to #{val}"
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
    #   any single peer. Changes apply to new connections or bindings only.
    #   Defaults to 1000.
    socket_option :sndhwm, :send_limit

    # @!attribute [rw] receive_limit
    #   The high water mark for inbound messages. This is a hard limit on
    #   the maximum number of received messages that can be queued from
    #   any single peer. Changes apply to new connections or bindings only.
    #   Defaults to 1000.
    socket_option :rcvhwm, :receive_limit

    # @!attribute [rw] send_timeout
    #   If set to a positive value, send operations will time out with an {EAGAIN}
    #   exception after that many milliseconds if the message cannot be sent.
    #   If set to 0, the socket will always raise {EAGAIN} if the message
    #   cannot be sent immediately. If set to -1, the socket will block
    #   indefinitely until the message can be sent. Changes apply to new
    #   connections or bindings only. Defaults to -1.
    socket_option :sndtimeo, :send_timeout

    # @!attribute [rw] receive_timeout
    #   If set to a positive value, receive operations will time out with an {EAGAIN}
    #   exception after that milliseconds if there are no messages to receive.
    #   If set to 0, the socket will always raise {EAGAIN} if there are no
    #   messages waiting. If set to -1, the socket will block indefinitely
    #   until a message is received. Changes apply to new connections or
    #   bindings only. Defaults to -1.
    socket_option :rcvtimeo, :receive_timeout

    # @!attribute [rw] affinity
    #   A bitmask declaring which of the context's I/O threads should
    #   handle this socket's messaging. The lowest bit corresponds to
    #   thread 1 in the context's thread pool, the second lowest bit to
    #   thread 2, and so forth. This is an advanced option for low-level
    #   performance tuning; most users should stick with the default value
    #   of 0, which distributes socket traffic across the context's pool.
    #   @see Context#io_threads
    socket_option :affinity

    # @!attribute [rw] rate
    #   The maximum send or receive data rate for multicast transports
    #   (i.e. **pgm://** or **epgm://**) in kilobits per second. Does not
    #   affect other transport types. Changes apply to new connections or
    #   bindings only. Defaults to 100.
    socket_option :rate

    # @!attribute [rw] recovery_interval
    #   For multicast transports only (**pgm://** and **epgm://**), the
    #   maximum time in milliseconds that a receiver can be missing before
    #   data is lost and will not be resent. Changes apply to new connections
    #   or bindings only. Defaults to 10,000 (10 seconds).
    socket_option :recovery_ivl, :recovery_interval

    # @!attribute [rw] send_buffer
    #   The transmit buffer size in bytes for underlying network sockets. A
    #   value of 0 will use the operating system default. Changes apply to
    #   new connections or bindings only. Defaults to 0.
    socket_option :sndbuf, :send_buffer

    # @!attribute [rw] receive_buffer
    #   The receive buffer size in bytes for underlying network sockets. A
    #   value of 0 will use the operating system default. Changes apply to
    #   new connections or bindings only. Defaults to 0.
    socket_option :rcvbuf, :receive_buffer

    # @!attribute [rw] reconnect_interval
    #   The waiting time in milliseconds between reconnection attempts when
    #   a network connection is broken. By default the waiting time does
    #   not change between connection attempts; for exponential backoff,
    #   also set the {#reconnect_interval_max} attribute. Changes apply to
    #   new connections only. Defaults to 100.
    socket_option :reconnect_ivl, :reconnect_interval

    # @!attribute [rw] reconnect_interval_max
    #   If greater than {#reconnect_interval}, enables exponential backoff
    #   for network reconnections (i.e., each subsequent attempt doubles the
    #   time between attempts) and represents the *maximum* waiting time in
    #   milliseconds. Changes apply to new connections only.
    #   Defaults to 0 (no exponential backoff).
    socket_option :reconnect_ivl_max, :reconnect_interval_max

    # @!attribute [rw] max_message_size
    #   The maximum allowed size in bytes for inbound messages. Peers
    #   sending larger messages will be disconnected. Changes apply to
    #   new connections or bindings only. Defaults to -1 (no limit).
    socket_option :maxmsgsize, :max_message_size

    # @!attribute [rw] multicast_hops
    #   For multicast transports only (**pgm://** or **epgm://**), the
    #   the packet time-to-live value. Changes apply to new connections
    #   or bindings only. Defaults to 1, meaning multicast messages will
    #   not leave the local network.
    socket_option :multicast_hops

    # @!attribute [rw] ipv4_only
    #   If set to 1 or *true*, TCP transports will use IPV4 sockets and
    #   will be unable to communicate with IPV6 hosts. Setting to 0 or
    #   *false* will direct transports to use IPV6 sockets, which can
    #   accept both IPV4 and IPV6 connections. Changes apply to new
    #   connections or bindings only. Defaults to 1 (true).
    socket_option :ipv4only, :ipv4_only

    # @see {#ipv4_only}
    def ipv4_only?
      ipv4_only == 1
    end

    # @!attribute [rw] delay_attach_on_connect
    #   If set to 1 or *true*, the socket will be closed and will block
    #   on message sending until at least one connection has been
    #   completed. Defaults to 0 (false), meaning messages will be
    #   accepted and queued while connections are made.
    socket_option :delay_attach_on_connect

    # @see {#delay_attach_on_connect}
    def delay_attach_on_connect?
      delay_attach_on_connect == 1
    end

    # @!attribute [rw] tcp_keepalive
    #   For TCP transports only, toggles {http://tldp.org/HOWTO/TCP-Keepalive-HOWTO/overview.html keepalive}
    #   for the underlying network socket. Set to 1 or *true* to enable
    #   keepalive, and 0 or *false* to disable. Changes apply to new connections
    #   only.  Defaults to -1, which defers to operating system settings.
    socket_option :tcp_keepalive

    # @!attribute [rw] tcp_keepalive_idle
    #   For TCP transports only, the delay in seconds between the last
    #   data packet sent and the beginning of keepalive packet. Changes
    #   apply to new connections only. Defaults to -1, which defers to
    #   operating system settings.
    #   @see http://tldp.org/HOWTO/TCP-Keepalive-HOWTO/usingkeepalive.html Using Keepalive Under Linux
    socket_option :tcp_keepalive_idle

    # @!attribute [rw] tcp_keepalive_interval
    #   For TCP transports only, the time between each keepalive packet.
    #   Changes apply to new connections only. Defaults to -1, which defers
    #   to operating system settings.
    #   @see http://tldp.org/HOWTO/TCP-Keepalive-HOWTO/usingkeepalive.html Using Keepalive Under Linux
    socket_option :tcp_keepalive_intvl, :tcp_keepalive_interval

    # @!attribute [rw] tcp_keepalive_count
    #   For TCP transports only, the number of keepalive packets to send
    #   before giving up and reporting a dead connection. Changes apply
    #   to new connections only. Defaults to -1, which defers to operating
    #   system settings.
    #   @see http://tldp.org/HOWTO/TCP-Keepalive-HOWTO/usingkeepalive.html Using Keepalive Under Linux
    socket_option :tcp_keepalive_cnt, :tcp_keepalive_count

    # @!attribute [r] tcp_accept_filters
    #   List of filters defined for this socket using {#tcp_accept_filter}.
    #   Defaults to an empty array.
    def tcp_accept_filters
      @tcp_accept_filters ||= []
    end

    # Assigns one or more {http://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing CIDR}
    # strings (e.g. `'192.168.0.0/16'`) as TCP connection filters for this
    # socket. If used, incoming connections must match at least one of the
    # filters or be rejected. CIDR strings may be IPV4 or IPV6. To clear
    # all filters, pass *nil*. Changes apply to new bindings only.
    # @see #tcp_accept_filters
    # @param [String, nil] *filters One or more IPV4 or IPV6 CIDR strings, or nil to clear all filters
    # @return [Array] List of all current filters defined using this method.
    def tcp_accept_filter(*filters)
      filters.each do |filter|
        self.tcp_accept_filter = filter
        if filter.nil?
          tcp_accept_filters.clear
        else
          tcp_accept_filters << filter
        end
      end
      tcp_accept_filters
    end

    # @!attribute [r] file_descriptor
    #   The operating system file descriptor for the socket, used by
    #   0mq to signal events. This is a low-level attribute that you will
    #   most likely never need unless you're building your own event loop.
    #   You should read and understand the `ZMQ_FD` option in the
    #   **zmq_getsockopt(3)** man page before you consider using this.
    #   @see http://api.zeromq.org/3-2:zmq-getsockopt
    get_option :fd, :file_descriptor

    # @!attribute [r] event_flags
    #   A bitfield representing the socket's readiness to receive a message
    #   {POLLIN} or or send a message {POLLOUT}. This is a low-level attribute
    #   intended for event loops. The {#receive_ready?} and {#send_ready?}
    #   methods break this value into more convenient booleans.
    get_option :events, :event_flags


  protected
    set_option :tcp_accept_filter
  end
end
