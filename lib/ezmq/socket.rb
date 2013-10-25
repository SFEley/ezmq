require 'ezmq/message'
require 'ezmq/message_frame'

module EZMQ

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

    # Returns the type number corresponding to this socket class.
    # Allows the class constant to be used as an integer value for the
    # 0MQ C API.
    def self.to_int
      @to_int ||= Types[type]
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
      reconnevt_ivl:            18,
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
