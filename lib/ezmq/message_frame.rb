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
  #    will be created. You can then add content to the buffer
  #    incrementally with the {#<<} operator or at any offset with the
  #    {#[]=} operator.
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
    #   Creates and initializes an empty 0MQ message structure. This is
    #   primarily useful as a container for receiving messages of arbitrary
    #   length.
    def initialize
      # @ptr = API::Pointer.malloc(33)
      # API::invoke :zmq_msg_init, @ptr
    end

    # The memory pointer to the 0MQ message object. You shouldn't need
    # to use this directly unless you're doing low-level work outside of
    # the EZMQ interface.
    # @return [Fiddler::Pointer]
    # @raise [ContextClosed] if the context has already been destroyed
    def ptr
      @ptr or raise ContextClosed
    end


  private


  end
end
