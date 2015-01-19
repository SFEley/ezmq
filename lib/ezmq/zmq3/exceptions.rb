require_relative 'api'

module EZMQ
  # The 0MQ code says: "A number random enough not to collide with
  # different errno ranges on different OSes." A base for error codes
  # that don't appear in the standard system errors. Don't ask me why it
  # has this name.
  HAUSNUMERO = 156384712

  # Lookup hash for all known 0MQ errors by number. Errors that map to
  # standard system errors (which is most of them) are referenced by
  # the standard error code AND 0MQ's custom number.
  ERRNOS = {}
  private_constant :HAUSNUMERO, :ERRNOS

  # Base exception class for all EZMQ errors, both from Ruby code and
  # from the 0MQ library.
  class EZMQError < StandardError; end

  # Raised on attempts to use a Context object after it's been destroyed.
  class ContextClosed < EZMQError; end

  # Raised on attempts to use a Socket object after it's been destroyed.
  class SocketClosed < EZMQError; end

  # Raised on attempts to use a MessageFrame object after it's been destroyed.
  class MessageFrameClosed < EZMQError; end

  # Raised when a bad address is given for binding or connecting.
  class InvalidEndpoint < EZMQError
    # @param endpoint [Object] The endpoint that wasn't valid.
    def initialize(endpoint, *args)
      super("Address '#{endpoint}' is not a valid endpoint.", *args)
    end
  end

  # Base exception class for all errors coming from the 0MQ library.
  # These are distinguished entirely by their numeric error code.
  # 0MQ tries to raise standard operating system error numbers whenever
  # possible; it defines its own only if the name doesn't already
  # exist.  To play it safe, we look up errors by the operating system
  # number (if there is one defined in Ruby's standard Errno exceptions)
  # _and_ by 0MQ's native numbers. The message strings are always
  # determined by the 0MQ API as well.
  class ZMQError < EZMQError
    Errno = nil
    Message = 'ZeroMQ error'

    # The numeric error code returned by 0MQ functions.
    def errno
      self.class::Errno
    end

    def message
      self.class::Message
    end

    def to_s
      "#{errno} - #{message}"
    end

    # Returns an exception object corresponding to a 0MQ error number.
    # @return [ZMQError, nil] An appropriate subclass of ZMQError, or UnknownError for an invalid error code.
    def self.for_errno(num)
      if ERRNOS[num]
        ERRNOS[num].new
      else
        UnknownError.new num
      end
    end

    # @private
    # Convenience method to auto-define all the exception classes for all
    # known error codes in `include/zmq.h`.
    def self.spawn(name, offset=0)
      the_errno = ::Errno.const_defined?(name) ? ::Errno.const_get(name)::Errno : HAUSNUMERO + offset
      spawned = Class.new(self)
      spawned.const_set :Errno, the_errno
      spawned.const_set :Message, API::zmq_strerror(the_errno).to_s
      EZMQ.const_set name, spawned
      ERRNOS[the_errno] = spawned
      if offset > 0 and the_errno < HAUSNUMERO
        ERRNOS[HAUSNUMERO + offset] = spawned
      end
    end
  end

  # Raised for errors coming out of ZeroMQ that aren't in our known list
  # for whatever reason. If we get a numeric error code at all, we'll
  # try to ask ZeroMQ what it means.
  class UnknownError < ZMQError
    attr_reader :errno, :message

    def initialize(*args)
      if (@errno = args.first.to_i) > 0
        @message = API::zmq_strerror(@errno)
      else
        @message = args.first
      end
      super
    end
  end

  # These errors will usually be reported by the operating system's error
  # code, but sometimes have alternatives:
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

  # The errors below are 0MQ-specific:
  ZMQError.spawn :EFSM, 51
  ZMQError.spawn :ENOCOMPATPROTO, 52
  ZMQError.spawn :ETERM, 53
  ZMQError.spawn :EMTHREAD, 54

  # The errors below don't have 0MQ-specific codes, so the operating
  # system code is always used:
  ZMQError.spawn :EINVAL
  ZMQError.spawn :ENOENT
  ZMQError.spawn :EFAULT
end
