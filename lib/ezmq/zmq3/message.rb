require 'delegate'

module EZMQ

  # A container class for multipart messages received from 0MQ. This class
  # *does not* map directly to any native 0MQ structures; rather, a
  # Message is a pure Ruby object collecting zero or more strings, which
  # are received or sent as separate "parts" or "frames." These are
  # copied automatically from the right 0MQ buffer types at the right
  # times, so there is no need to manage individual frames unless you
  # have specialized needs. (If you do, read the docs for EZMQ::MessageFrame
  # and forget this class exists.)
  #
  # Real-world use cases vary on whether it makes more sense to treat
  # messages as single blobs of data or as collections of frames. The
  # Message class does its best to act as both a particle *and* a wave;
  # each object can be coerced to a string or an array. When treated as a
  # string, multiple frames are joined using the *frame_separator* attribute.
  # String data is assumed to be 8-bit binary but can be marked as any
  # other encoding (e.g. UTF-8) with the *encoding* attribute. Both
  # can be given new defaults with the Message::frame_separator or
  # Message::encoding attributes.
  #
  # @note You will most frequently encounter Message objects when
  # *receiving* from 0MQ sockets. You can certainly use them for sending
  # as well, but since the Socket#send method takes strings or arrays
  # there isn't much need to bother except when forwarding.
  #
  # @note Power users should note that the data within Message objects
  # is *copied* from 0MQ's buffers. This can have memory and performance
  # implications when dealing with very large message frames (i.e. hundreds
  # of megabytes or more). Zero-copy message handling isn't attempted; the
  # mechanics for doing so are complex and error-prone, and Ruby's just not
  # good at that sort of direct access. Instead we aim for efficiency by
  # reusing 0MQ message buffers and clearing them frequently.
  class Message < DelegateClass(Array)
    include Comparable

    class << self
      # The default encoding for messages when treated as a string.
      # Defaults to Encoding::BINARY.
      attr_accessor :encoding

      # The default separator to be placed between message frames when
      # the Message is cast to a string. Defaults to an empty string
      # (simple concatenation).
      attr_accessor :frame_separator
    end
    self.encoding = Encoding::BINARY
    self.frame_separator = ''

    attr_reader :frames
    attr_writer :frame_separator, :encoding


    # Creates a new Message object. The object can begin life empty or can
    # be initialized from one or more strings or MessageFrame objects.
    def initialize(*frames)
      if frames.last.respond_to?(:fetch)
        opts = frames.pop
        @encoding = opts[:encoding] if opts[:encoding]
        @frame_separator = opts[:frame_separator] if opts[:frame_separator]
      end

      @frames = frames
      super(@frames)
    end

    # @!attribute [r]
    def encoding
      @encoding || self.class.encoding
    end

    # @!attribute [r]
    def frame_separator
      @frame_separator || self.class.frame_separator
    end

    # Coerces the object into a string. The individual frames of the
    # message are joined using the #frame_separator (defaults to an empty
    # string), and each individual frame is transcoded into the #encoding
    # attribute (which you should leave at the 8-bit binary default if
    # you're uncertain).
    def to_str
      if frames.empty?
        ''.force_encoding(encoding)
      else
        frames.inject(nil) do |str, frame|
          if str
            str << frame_separator.encode(encoding)
          else
            str = ''.force_encoding(encoding)
          end
          str << frame.encode(encoding)
        end
      end
    end
    alias_method :to_s, :to_str

    # Equality. A Message is equal to another object if it tests true
    # using either String#== when cast to a string *or* Array#== for its
    # frames (in that order).
    def ==(val)
      String.new(self) == val or super
    end

    # Comparison. A Message is first cast to a string and String#<=> is
    # tested. If no value is returned, the message frames are tested using
    # Array#<=>. The standard comparison operators (`<`, '<=', '>', '>='
    # and `between?`) are implemented using Comparable.
    def <=>(val)
      String.new(self) <=> val or super
    end

    # Match. Equivalent to String#=~.
    def =~(val)
      String.new(self) =~ val
    end

    # Equivalent to String#match.
    def match(val)
      String.new(self).match val
    end
  end
end
