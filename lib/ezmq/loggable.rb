require 'logger'

module EZMQ

  # @!attribute [rw] logger
  #   The global logger for EZMQ objects. Points to a null object by
  #   default; to enable logging simply assign any Ruby Logger-compatible
  #   object.
  #   @see Loggable
  def self.logger
    @logger ||= NullLogger.new
  end

  def self.logger=(val)
    @logger = val || NullLogger.new
  end

  # EZMQ's facilities for logging 0MQ activity are disabled by default.
  # To enable logging for all contexts, sockets, and message buffers, set
  # the global {EZMQ.logger} attribute to any object that conforms to the
  # {http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger.html Ruby Logger}
  # interface.
  #
  # @example Emit console errors on warnings and failures
  #   EZMQ.logger = Logger.new(STDERR)
  #   EZMQ.logger.level = Logger::WARN
  #
  # If your application already has logging, you can assign the same logging
  # object to EZMQ.
  #
  # @example Rails integration
  #   EZMQ.logger = Rails.logger
  #
  # You can also set custom loggers for individual objects, overriding the
  # global default. A different logger can be supplied at initialization or
  # at runtime.
  #
  # @example Custom logger at socket creation
  #   req_logger = Logger.new('requests.log', 'daily')  # Rotating logfile
  #   requester = EZMQ::REQ.new(logger: req_logger)
  #
  # @example Override logger for testing
  #   # Assume you're specifying behavior for a socket in RSpec
  #   describe MyAppSocket do
  #     before(:each) do
  #       @logged = StringIO.new
  #       subject.logger = Logger.new(@logged)
  #     end
  #
  #     it "sends messages out" do
  #       subject.send 'Hello!'
  #       expect(@logged.to_s).to match /Sent 6 bytes/
  #     end
  #   end
  #
  # ## What Gets Logged
  #
  # EZMQ observes the following log levels for consistency:
  #
  # * `ERROR` - Exceptions indicating permanent failures or actions that
  #   should not succeed. Examples:
  #     * DNS lookup failures on connection
  #     * sending a message to a closed socket
  #     * sending two {REQ} messages in a row without a reply
  # * `WARN` - Transient or unusual behavior due to timeouts, thresholds,
  #   or network conditions. Examples:
  #     * send failures when the high water mark has been reached
  #     * receiving with *async: true* when no messages are pending
  #     * a received message part is truncated due to size limits
  #     * message logging is enabled for a socket _(see below)_
  # * `INFO` - Context and socket activity related to opening, closing, and
  #   connections:
  #     * contexts are created or destroyed
  #     * sockets are created or destroyed
  #     * socket binding and unbinding
  #     * socket connecting and disconnecting
  #     * SUB socket subscribes and unsubscribes
  # * `DEBUG` - Message activity and changes to socket attributes.
  #
  # ## Logging Messages
  #
  # By default, log entries that reference specific messages do not contain
  # details that could directly identify the message or its content. Debug
  # entries contain the number of bytes sent or received and whether the
  # message part has more to follow; warnings and errors merely state that a
  # failure occurred. This is the safest approach from an information
  # privacy standpoint but can make it difficult to trace programming or
  # network errors when things go wrong.
  #
  # The {Socket#log_messages} attribute enables part or all of a message to
  # be captured in relevant log entries. If passed an integer, the logger
  # will append the first _n_ bytes of every message part to the log entry.
  # If given a regular expression, the first match within the message part
  # will be appended. The literal _true_ will append the entire message
  # part -- strongly discouraged unless your messages are always short.
  # Setting it to _false_ or _nil_ (the default) will disable content
  # logging.
  #
  # This option has no global setting by design; it must be applied on a
  # per-socket basis, and the act of setting it is logged as a warning due
  # to the performance and security impact. We _highly_ recommend using
  # this option only in development and testing environments. If you enable
  # it in production to solve a specific issue, consider logging to a
  # stream watched by a human rather than disk, and disable it when
  # no longer needed.
  module Loggable
    # Logger for 0MQ events on this object. Defaults to {EZMQ.logger}
    # if not overridden.
    attr_accessor :logger

    def debug(msg=nil, &block)
      logger.add Logger::DEBUG, msg, name, &block
    end

    def info(msg=nil, &block)
      logger.add Logger::INFO, msg, name, &block
    end

    def warn(msg=nil, &block)
      logger.add Logger::WARN, msg, name, &block
    end

    def error(msg=nil, &block)
      logger.add Logger::ERROR, msg, name, &block
    end
  end

  # @private
  # @see http://hawkins.io/2013/08/using-the-ruby-logger/
  class NullLogger < ::Logger
    def initialize(*args)
      self.level = Logger::UNKNOWN
    end

    def add(*args, &block)
    end
  end



end
