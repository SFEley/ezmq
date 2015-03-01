module EZMQ
  class Socket

    # Implements methods for sending messages.
    module Sendable

      # Sends a single- or multi-part message on the socket. Messages can be
      # single strings, lists of strings, or {Message} objects. If you want to
      # delay sending until more parts can be delivered, use the `more: true`
      # option for all but the last part.
      #
      # If the message
      # can't be immediately queued -- no connections, the sending high-water
      # mark was reached, etc. -- the default behavior is to block until it
      # can be sent. You can alter this by either passing the `async: true`
      # option (which will raise a {ZMQError::EAGAIN} on a temporary send
      # failure) or by passing a block implementing your own behavior for
      # resending, logging the failure, or whatever else is appropriate. The
      # block will receive a {Message} containing all parts that have been
      # queued for the current send.
      #
      # @note We are well aware that this method name conflicts with the
      # basic Ruby {Object#send} for calling arbitrary methods. We are *not*
      # breaking that behavior; if the first argument to the method call is
      # a Symbol, we fall back to the inherited {Object#send}. Make sure
      # you're always sending strings or Messages to avoid accidental method
      # invocation.
      #
      # @param *parts [String, Array<String>, Message] The content to be delivered.
      # @param opts [Hash, optional] Options for additional parts or non-blocking.
      # @option opts [Boolean] :more If true, don't send immediately; wait for additional parts.
      # @option opts [Boolean] :async If true, raises {EAGAIN} if the message can't be queued for sending immediately.
      # @yieldparam message [Message] Accumulated parts of the message that was delayed.
      # @return [Fixnum] The total number of bytes queued for sending.
      def send(*parts)
        return super if parts.first.is_a?(Symbol)

        if parts.last.respond_to?(:fetch)
          opts = parts.pop
        else
          opts = {}
        end

        @partcount ||= 0
        @more = false

        while part = parts.shift
          @more = !parts.empty? || opts[:more]
          content_ptr = API::pointer_from part
          flags = 0
          flags += 1 if opts[:async]
          flags += 2 if @more

          API::invoke :zmq_send, self, content_ptr, content_ptr.size, flags
          debug do
            msg = "Sent part #{@partcount} (#{content_ptr.size} bytes)"
            @more ? msg + ' [MORE]' : msg
          end
          @partcount = (@more ? @partcount + 1 : nil)
        end
      end


      # True if the socket is able to {#send} without blocking. (I.e.,
      # if the #send_limit high-water mark has not yet been reached.)
      def send_ready?
        event_flags & POLLOUT == POLLOUT
      end


      # Sends the message content from a {MessageFrame} object, clearing its
      # contents after transmission. This is considered an advanced feature, making
      # use of the more complex `zmq_msg_send` API. Users who don't have
      # complex memory or routing requirements are encouraged to use the
      # {#send} method instead.
      # @param [MessageFrame] frame
      # @param [Hash, optional] opts
      # @option opts [Boolean] :more If true, don't send immediately; wait for additional parts.
      # @option opts [Boolean] :async If true, raises {EAGAIN} when a message temporarily can't be sent.
      # @return [Fixnum] The number of bytes sent from the frame.
      def send_from_frame(frame, opts={})
        flags = 0
        flags += 1 if opts[:async]
        flags += 2 if opts[:more]
        API::invoke :zmq_msg_send, frame, self, flags
      end

    end
  end
end
