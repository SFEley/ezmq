require 'ezmq/message'
require 'ezmq/message_frame'

module EZMQ

  class << self
    # The default `ZMQ_LINGER` socket value. Any sockets that do not set a
    # different value for their *linger* attribute on the socket or its class
    # will inherit this one upon creation.
    #
    # **IMPORTANT:** EZMQ sets this global default to 1000 milliseconds,
    # ensuring that 0MQ will not hang more than one second upon exit
    # even if there are pending messages. Set `EZMQ.linger = nil` to clear
    # the global default and fall back to 0MQ's default of -1, meaning
    # that closing a socket or context will potentially hang forever if
    # messages cannot be delivered.  (Danger Will Robinson!)
    # @see Socket#linger
    attr_accessor :linger
  end
  self.linger = 1000

  class Socket

    # From include/zmq.h
    Types = {
      PAIR:   0,
      PUB:    1,
      SUB:    2,
      REQ:    3,
      REP:    4,
      DEALER: 5,
      XREQ:   5,    # Deprecated alias
      ROUTER: 6,
      XREP:   6,    # Deprecated alias
      PULL:   7,
      PUSH:   8,
      XPUB:   9,
      XSUB:   10
    }

    # The name of this particular kind of socket, as a symbol.
    def self.type
      @shortname ||= name.rpartition('::')[2].to_sym
    end

    # The name of this particular kind of socket, as a symbol.
    def type
      self.class.type
    end

    class << self
      # The default `ZMQ_LINGER` socket value for new sockets of this class.
      # Undefined by default, so the global `EZMQ.linger` value will be used
      # instead.
      # @see Socket#linger
      attr_accessor :linger
    end


    # Returns the type number corresponding to this socket class.
    # Allows the class constant to be used as an integer value for the
    # 0MQ C API.
    def self.to_int
      @to_int ||= Types[type]
    end

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

  private
    # Simple counter to ensure sockets are distinguishable
    @@socketnum = 0

    def nextname
      "#{type}-#{@@socketnum += 1}"
    end
  end
end
