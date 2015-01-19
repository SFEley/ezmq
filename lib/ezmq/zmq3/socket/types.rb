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
  end
end
