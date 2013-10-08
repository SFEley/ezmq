require 'delegate'

module EZMQ
  # A container class for multipart messages received from 0MQ. This class
  # *does not* map directly to any native 0MQ structures; rather, a
  # Message is a pure Ruby object collecting zero or more strings, which
  # are received or sent as separate "parts" or "frames." These are
  # copied automatically from the right 0MQ buffer types at the right
  # times, so there is no need to manage individual frames unless you
  # have specialized needs. (If you do, read the docs for EZMQ::MessagePart
  # and forget this class exists.)
  #
  # Real-world use cases vary on whether it makes more sense to treat
  # messages as single blobs of data or as collections of parts. The
  # Message class does its best to act as both a particle *and* a wave;
  # each object can be coerced to a string or an array. When treated as a
  # string, multiple parts are joined using the *part_separator* attribute.
  # String data is assumed to be 8-bit binary but can be marked as any
  # other encoding (e.g. UTF-8) with the *encoding* attribute. Both
  # can be given new defaults with the Message::part_separator or
  # Message::encoding attributes.
  #
  # @note You will most frequently encounter Message objects when
  # *receiving* from 0MQ sockets. You can certainly use them for sending
  # as well, but since the Socket#send method takes strings or arrays
  # there isn't much need to bother except when forwarding.
  #
  # @note Power users should note that the data within Message objects
  # is *copied* from 0MQ's buffers. This can have memory and performance
  # implications when dealing with very large message parts (i.e. hundreds
  # of megabytes or more). Zero-copy message handling isn't attempted; the
  # mechanics for doing so are complex and error-prone, and Ruby's just not
  # good at that sort of direct access. Instead we aim for efficiency by
  # reusing 0MQ message buffers and clearing them frequently.
  class Message < DelegateClass(Array)
    attr_reader :parts

    # Creates a new Message object. The object can begin life empty or can
    # be initialized from one or more strings or MessagePart objects.
    def initialize(*parts)
      @parts = parts
      super(@parts)
    end
  end
end
