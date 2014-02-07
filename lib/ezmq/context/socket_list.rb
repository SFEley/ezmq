require 'weakref'

module EZMQ
  class Context

    # @private
    # A thread-safe, weak-referenced array of sockets attached to this
    # Context. Closed or garbage collected sockets are dropped whenever
    # the list is iterated.
    class SocketList
      include Enumerable

      def initialize
        @sockets = []
        @mutex = Mutex.new
      end

      def <<(socket)
        mutex.synchronize {sockets << WeakRef.new(socket)}
      end

      def each(&block)
        mutex.synchronize do
          sockets.keep_if {|socket| alive?(socket)}
          sockets.each &block
        end
      end

    private
      attr_reader :sockets, :mutex

      def alive?(socket)
        !socket.closed?
      rescue WeakRef::RefError
        false
      end
    end
  end
end
