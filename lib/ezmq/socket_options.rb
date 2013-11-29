module EZMQ
  class Socket

    # From include/zmq.h
    Options = {
      affinity:                 4,
      identity:                 5,
      subscribe:                6,
      unsubscribe:              7,
      rate:                     8,
      recovery_ivl:             9,
      sndbuf:                   11,
      rcvbuf:                   12,
      rcvmore:                  13,
      fd:                       14,
      events:                   15,
      type:                     16,
      linger:                   17,
      reconnect_ivl:            18,
      backlog:                  19,
      reconnect_ivl_max:        21,
      maxmsgsize:               22,
      sndhwm:                   23,
      rcvhwm:                   24,
      multicast_hops:           25,
      rcvtimeo:                 27,
      sndtimeo:                 28,
      ipv4only:                 31,
      last_endpoint:            32,
      router_mandatory:         33,
      fail_unroutable:          33,   # Deprecated alias
      router_behavior:          33,   # Deprecated alias
      tcp_keepalive:            34,
      tcp_keepalive_cnt:        35,
      tcp_keepalive_idle:       36,
      tcp_keepalive_intvl:      37,
      tcp_accept_filter:        38,
      delay_attach_on_connect:  39,
      xpub_verbose:             40
    }

    # @api private
    # Sets up a retrievable socket option as a reader attribute.
    def self.get_option(name, *aliases)
      define_method name do
        val_pointer = API::Pointer.malloc(API::INT_SIZE)
        size_pointer = API::Pointer.malloc(API::SIZE_T_SIZE)
        size_pointer[0] = API::INT_SIZE
        API::invoke :zmq_getsockopt, self, Options[name], val_pointer, size_pointer
        val_pointer.to_s(size_pointer[0].to_i).unpack('i').first
      end
      aliases.each {|a| alias_method a, name}
    end

    # @api private
    # Sets up a settable socket option as a writer attribute.
    def self.set_option(name, *aliases)
      define_method "#{name}=".to_sym do |val|
        val_pointer = API::Pointer.malloc(API::INT_SIZE)
        val_pointer[0, API::INT_SIZE] = [val].pack('i')
        API::invoke :zmq_setsockopt, self, Options[name], val_pointer, API::INT_SIZE
        send name
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
