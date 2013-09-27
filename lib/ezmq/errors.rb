module EZmq
  # 0mq tries to raise standard operating system error numbers whenever
  # possible; it defines its own only if the name doesn't already
  # exist.  To play it safe, we look up errors by the operating system
  # number (if there is one defined in Ruby's standard Errno exceptions)
  # _and_ by 0mq's native numbers. 0mq's message strings are always used.
  module Errors
    # The 0mq code says: "A number random enough not to collide with
    # different errno ranges on different OSes." A base for error codes
    # that don't appear in the standard system errors. Don't ask me why it
    # has this name.
    HAUSNUMERO = 156384712
    private_constant :HAUSNUMERO

    # Lookup hash for all known 0mq errors by number. Errors that map to
    # standard system errors (which is most of them) are referenced by
    # the standard error code AND 0mq's custom number.
    def self.errnos
      @errnos ||= {}
    end

    # Base exception class for all errors coming from the 0mq library.
    # These are distinguished entirely by their numeric error code, and
    # message strings are determined by 0mq as well.
    class ZMQError < StandardError
      def self.errno
        0
      end

      def errno
        self.class.errno
      end

      # @private
      def self.spawn(name, offset)
        Errors.const_set name, Class.new(self) do
          def self.errno
            HAUSNUMERO + offset
          end
        end
      end
    end

    ZMQError.spawn :ENOTSUP,  1
    ZMQError.spawn :EPROTONOSUPPORT, 2
    ZMQError.spawn :ENOBUFS, 3
    ZMQError.spawn :ENETDOWN, 4
    ZMQError.spawn :EADDRINUSE, 5
    ZMQError.spawn :EADDRNOTAVAIL, 6
    ZMQError.spawn :ECONNREFUSED, 7
    ZMQError.spawn :EINPROGRESS, 8
    ZMQError.spawn :ENOTSOCK, 9
    ZMQError.spawn :EMSGSIZE, 10
    ZMQError.spawn :EAFNOSUPPORT, 11
    ZMQError.spawn :ENETUNREACH, 12
    ZMQError.spawn :ECONNABORTED, 13
    ZMQError.spawn :ECONNRESET, 14
    ZMQError.spawn :ENOTCONN, 15
    ZMQError.spawn :ETIMEDOUT, 16
    ZMQError.spawn :EHOSTUNREACH, 17
    ZMQError.spawn :ENETRESET, 18

    # The errors below are 0mq-specific and never system error codes
    ZMQError.spawn :EFSM, 51
    ZMQError.spawn :ENOCOMPATPROTO, 52
    ZMQError.spawn :ETERM, 53
    ZMQError.spawn :EMTHREAD, 54
  end
end
