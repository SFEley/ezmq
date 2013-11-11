module EZMQ
  # Wraps a 0MQ message `zmq_msg_t` structure for use with the `zmq_msg_*`
  # family of API functions. This is a low-level class that most **EZMQ**
  # end users won't need to use directly, but if you want to pre-allocate
  # messages for memory purposes or otherwise take responsibility for the
  # lifecycle of your buffers, here you go.
  #
  # Important safety tips, thanks Egon:
  #
  # 1. The 0MQ message structure is initialized with either `zmq_msg_init`
  #    or `zmq_msg_init_size` when the {MessageFrame} is created. The 0MQ docs
  #    warn against initializing the same message twice, so don't call
  #    those functions yourself on these objects.
  # 2. The easiest way to populate a {MessageFrame} with data to send is to
  #    pass the data (as a string of any encoding) on initializing.
  # 3. If you pass an integer instead, an empty buffer of the given size
  #    will be created. You can then add content to the buffer with the
  #    {#data=} method or at any offset with the {#[]=} operator.
  # 4. Initializing with no string or integer will create an "empty"
  #    {MessageFrame}. This is ideal for receiving, and you can copy or
  #    move data into it from _other_ {MessageFrame}s, but you will not
  #    be able to add data to it directly.
  # 5. A sized {MessageFrame} cannot be resized. You can modify its data
  #    in place, or replace its data completely with the move/copy methods,
  #    but attempting to append or access data above the size limit will
  #    raise an exception.
  # 6. To avoid ambiguity, the `zmq_msg_copy` API is implemented twice on
  #    every object as {#copy_to(dest)} and {#copy_from(src)}. It's also used
  #    if you {#clone} or {#dup} the object. This form of copy creates a
  #    second reference to the same memory buffer. Don't attempt to
  #    modify the data after you do this. Just don't.
  # 7. Likewise, the `zmq_msg_move` API is implemented as {#move_to(dest)}
  #    and {#move_from(src)}. These replace the destination's memory
  #    buffer with the source's, and the source becomes an empty
  #    {MessageFrame}.
  # 8. If you don't intend to use this {MessageFrame} again, call {#close}
  #    as soon as you're finished with it. If you don't, it will
  #    eventually happen in a finalizer when the object gets garbage
  #    collected, but you shouldn't want to resort to that. Not only is it
  #    much slower, but the message buffers themselves are outside of Ruby's
  #    memory space and thus won't trigger garbage collection. If you're
  #    dealing with large messages you may find yourself running out of
  #    memory without the Ruby interpreter noticing.
  # 9. The `zmq_msg_init_data` API is not implemented. Its purpose and
  #    semantics just don't make a lot of sense for Ruby.
  class MessageFrame

    # @overload initialize()
    #   Creates and initializes an empty 0MQ message structure with no
    #   set size. This is primarily useful as a container for receiving
    #   messages of arbitrary length.
    # @overload initialize(size)
    #   Creates and initializes an empty 0MQ message structure with a buffer
    #   of the given size. This can be filled with data in subsequent calls.
    #   @param [Fixnum] val Maximum size of content that can be handled.
    # @overload initialize(content)
    #   Creates and initializes a 0MQ message structure with a buffer
    #   containing the given string.
    #   @param [String] val String to be delivered.
    def initialize(val=nil)

      @ptr = API::Pointer.malloc(32)
      case val
      when nil
        API::invoke :zmq_msg_init, @ptr
      when Fixnum
        API::invoke :zmq_msg_init_size, @ptr, val
      when String
        API::invoke :zmq_msg_init_size, @ptr, val.bytesize
        self.data = val
      end

      # Clean up if garbage collected
      @destroyer = self.class.finalize(@ptr)
      ObjectSpace.define_finalizer self, @destroyer
    end

    # The memory pointer to the 0MQ message object. You shouldn't need
    # to use this directly unless you're doing low-level work outside of
    # the EZMQ interface.
    # @return [API::Pointer]
    # @raise [MessageFrameClosed] if this message structure has already been freed
    def ptr
      @ptr or raise MessageFrameClosed
    end

    # The memory pointer to the 0MQ message object. Differs from the
    # #ptr method in that it returns a null pointer if the context has
    # been destroyed rather than throwing an exception. Enables API
    # functions to accept this object wherever a context pointer would
    # be needed.
    # @return [API::Pointer]
    def to_ptr
      ptr
    rescue MessageFrameClosed
      API::NULL
    end

    # The length in bytes of the message content in memory. This value
    # is always retrieved from the `zmq_msg_size` 0MQ API call, so it
    # should remain accurate across buffer reallocations, etc.
    # @return [Fixnum]
    def size
      API::invoke :zmq_msg_size, self
    end

    # The content of the message buffer as known to 0MQ. This is a binary
    # encoded string of exactly {#size} bytes. Allocated buffers without
    # content will contain null bytes or garbage.
    # @return [String]
    # @see #[] if you want a subset of the data
    # @see #to_s if you want to treat the contents as text
    def data
      content_ptr.to_s(size)
    end
    alias_method :to_s, :data


    # Sets the content of the message buffer up to the allocated {#size}
    # or the length of the given string (whichever is less). Attempts to
    # set data beyond the allocated size will silently fail.
    # @return [String] The new contents of the data buffer
    def data=(val)
      if (val_size = val.bytesize) < (buffer_size = size)  # Reduce duplicate calls
        content_ptr[0, val_size] = val
      else
        content_ptr[0, buffer_size] = val.byteslice(0, buffer_size)
      end
      data
    end

    # The content of the message buffer from the given offset up to the given
    # length (or the end of the buffer allocation). If no length is given,
    # a single byte will be returned. An offset beyond the end of the
    # buffer will raise an exception.
    # @param [Fixnum] offset Starting byte of slice with 0 as the first byte
    # @param [Fixnum] length Number of bytes to return (defaults to 1)
    # @return [String]
    # @raise [IndexError] if the offset runs beyond the end of the buffer
    # @see #data
    def [](offset, length=1)
      if offset >= (buffer_size = size)
        raise IndexError, "Offset #{offset} exceeds frame size (#{buffer_size})"
      end
      bounded_length = [length, buffer_size - offset].min
      content_ptr[offset, bounded_length]
    end

    # Sets the content of the message buffer from the given offset up to the
    # given length, the length of the provided string in bytes, or the end
    # of the buffer allocation (whichever is less). An offset beyond the
    # end of the buffer will raise an exception.
    # @param [Fixnum] offset Starting byte of slice with 0 as the first byte
    # @param [Fixnum] length Number of bytes to pull from the provided string (default is string length)
    # @return [String] The substituted part of the string
    # @raise [IndexError] if the offset runs beyond the end of the buffer
    # @see #data=
    def []=(offset, length=nil, val)
      if offset >= (buffer_size = size)
        raise IndexError, "Offset #{offset} exceeds frame size (#{buffer_size})"
      end
      val_size, rest_of_buffer = val.bytesize, (buffer_size - offset)
      bounded_length = [val_size, rest_of_buffer, length || val_size].min
      val = val.byteslice(0, bounded_length) if bounded_length < val_size
      content_ptr[offset, bounded_length] = val
      val
    end

    # True if this is a received message part and there are more to follow.
    def more?
      API::invoke(:zmq_msg_more, self) > 0
    end


    # Tells 0MQ to set the target {MessageFrame} to have the same contents
    # as this one. Both objects may point to the same buffer in memory (but
    # this is not guaranteed). If the other frame already had data, that
    # buffer will be released.
    # @param [MessageFrame] target
    # @return [MessageFrame] The target object
    def copy_to(target)
      API::invoke :zmq_msg_copy, target, self
      target
    end


    # Tells 0MQ to get new contents from the source {MessageFrame}. Both
    # objects may point to the same buffer in memory (but this is not
    # guaranteed). If this object already had data, that buffer
    # will be released.
    # @param [MessageFrame] source
    # @return [MessageFrame] self
    def copy_from(source)
      API::invoke :zmq_msg_copy, self, source
      self
    end

    # Tells 0MQ to transfer this object's contents to the target {MessageFrame}.
    # This object will become an empty frame.
    # @param [MessageFrame] target
    # @return [MessageFrame] The target object
    def move_to(target)
      API::invoke :zmq_msg_move, target, self
      target
    end

    # Tells 0MQ to transfer contents from the source {MessageFrame} to this
    # one. The source object will become an empty frame.
    # @param [MessageFrame] source
    # @return [MessageFrame] self
    def move_from(source)
      API::invoke :zmq_msg_move, self, source
      self
    end

    # @private
    def initialize_copy(other)
      initialize
      copy_from other
    end


    # Tells 0MQ that this object is no longer required.
    # Attempting to access the MessageFrame after this will throw an exception.
    # @note This also occurs when the Context object is garbage collected.
    def close
      destroyer.call
      @ptr = nil
    end
    alias_method :destroy, :close
    alias_method :terminate, :close


    # Creates a routine that will safely close any sockets and terminate
    # the 0MQ context upon garbage collection.
    def self.finalize(ptr)
      Proc.new do
        API::invoke :zmq_msg_close, ptr
      end
    end

  private
    attr_reader :destroyer

    def content_ptr
      API::invoke :zmq_msg_data, self
    end


  end
end
