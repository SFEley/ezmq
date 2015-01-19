module EZMQ
  class Socket

    # Implements methods for receiving messages.
    module Receivable

      # Receives a message from the socket. The return is a {Message} object
      # containing one or more parts, which duck types reasonably well to a
      # String or to an Array.
      #
      # If no message is immediately available, the default behavior is to
      # block until one arrives. You can assure a fast return by setting the
      # `async: true` option, which will raise a {ZMQError::EAGAIN} if no
      # message is available. (Event-driven callbacks are planned for a
      # future release.)
      #
      # @note By default, message parts are received using the 0MQ
      # `zmq_msg_recv` API, which allows content of any length but is
      # moderately complex and requires multiple Ruby steps to manage
      # memory structures.  If you know your message parts will never exceed
      # a certain length (or if you want to cap them on purpose to avoid
      # memory overruns) consider using the *:size* option, which will
      # trigger the simpler and marginally faster `zmq_recv` API. Message parts
      # larger than your stated *:size* in bytes will be truncated; parts
      # of that size or smaller will be unaffected.

      #
      # @param [Hash, optional] opts
      # @option opts [Boolean] :async If true, raises {EAGAIN} when a message is not yet available.
      # @option opts [Fixnum] :size If specified, each message part is captured in a fixed-size buffer and truncated at the given byte limit.
      # @return [Message]
      def receive(opts={})
        message = Message.new receive_part(opts)
        while more?
          debug {"Received part #{message.length - 1} (#{message.last.bytesize} bytes) [MORE]"}
          message << receive_part(opts)
        end
        debug {"Received part #{message.length - 1} (#{message.last.bytesize} bytes)"}
        message
      end

      # Gets a single message part from the socket. There may or may not be
      # more parts after this one; use {#more?} to check.
      #
      # If no message is immediately available, the default behavior is to
      # block until one arrives. You can assure a fast return by setting the
      # `async: true` option, which will raise a {ZMQError::EAGAIN} if no
      # message is available. (Event-driven callbacks are planned for a
      # future release.)
      #
      # @note By default, message parts are received using the 0MQ
      # `zmq_msg_recv` API, which allows content of any length but is
      # moderately complex and requires multiple Ruby steps to manage
      # memory structures.  If you know your messages will never exceed
      # a certain length (or if you want to cap them on purpose to avoid
      # memory overruns) consider using the *:size* option, which will
      # trigger the simpler and marginally faster `zmq_recv` API. Messages
      # larger than your stated *:size* in bytes will be truncated; messages
      # of that size or smaller will be unaffected.
      #
      # @note If you fail to retrieve every part
      # of a message in progress, blocking or other strange things may happen.
      # Using this method makes you responsible for your own flow control.
      # Unless your use case or data sizes compel you to process parts
      # incrementally, it *usually* makes more sense to use the {#receive}
      # method to get all parts at once.
      #
      # @param [Hash, optional] opts
      # @option opts [Boolean] :async If true, raises {EAGAIN} when a message is not yet available.
      # @option opts [Fixnum] :size If specified, capture the part in a fixed-size buffer and truncate it at the given byte limit.
      # @return [String] Received message data with binary encoding.
      def receive_part(opts={})
        if size = opts[:size]
          ptr = FFI::MemoryPointer.new :char, size
          received_size = API::invoke :zmq_recv, self, ptr, size, 0
          ptr.read_string [size, received_size].min
        else
          receive_into_frame(receive_frame, opts)
          receive_frame.to_s
        end
      end

      # Receives a message part into a {MessageFrame} object, clearing any
      # existing contents. This is considered an advanced feature, making
      # use of the more complex `zmq_msg_recv` API. Users who don't have
      # complex memory or routing requirements are encouraged to use the
      # {#receive} method instead.
      # @param [MessageFrame] frame
      # @param [Hash, optional] opts
      # @option opts [Boolean] :async (false) If true, raises {EAGAIN} when a message is not yet available.
      # @return [Fixnum] The number of bytes received into the frame.
      def receive_into_frame(frame, opts={})
        API::invoke :zmq_msg_recv, frame, self, (opts[:async] ? 1: 0)
      end


      # True if the socket has received a multi-part message and currently
      # has more parts waiting to be processed; otherwise false.
      def more?
        rcvmore == 1
      end

      # True if the socket is able to {#receive} without blocking. (I.e.,
      # if there is at least one complete message in the queue.)
      def receive_ready?
        event_flags & POLLIN == POLLIN
      end

    private

      def receive_frame
        @receive_frame ||= MessageFrame.new
      end

      def recv(size, async)
        ptr = FFI::MemoryPointer.new :char, size
        received_size = API::invoke :zmq_recv, self, ptr, size, 0
        ptr.read_string [size, received_size].min
      end


    end
  end
end
