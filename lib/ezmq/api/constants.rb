module EZmq
  module API
    # The 0mq library declares all of its option types, etc. as integers
    # with `#define`-based constant names. This is inconvenient for
    # working with them in Ruby. Rather than clutter our code (or yours)
    # up with scores of ugly constants, we group them into a few hashes.
    module Constants
      SocketTypes = {
        pair:     0,
        pub:      1,
        sub:      2,
        req:      3,
        rep:      4,
        dealer:   5,
        xreq:     5,  # Deprecated; now alias for DEALER
        router:   6,
        xrep:     6,  # Deprecated; now alias for ROUTER
        pull:     7,
        push:     8,
        xpub:     9,
        xsub:     10
      }.freeze

      SocketOptions = {
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
        fail_unroutable:          33,   # Deprecated; now alias for ROUTER_MANDATORY
        router_behavior:          33,   # Deprecated; now alias for ROUTER_MANDATORY
        tcp_keepalive:            34,
        tcp_keepalive_cnt:        35,
        tcp_keepalive_idle:       36,
        tcp_keepalive_intvl:      37,
        tcp_accept_filter:        38,
        delay_attach_on_connect:  39,
        xpub_verbose:             40
      }.freeze

      MessageOptions = {
        more: 1
      }.freeze

      SendRecvOptions = {
        dontwait: 1,
        noblock:  1,  # Deprecated; now alias for DONTWAIT
        sndmore:  2
      }.freeze

    end
  end
end
