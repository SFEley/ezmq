require 'ezmq/loggable'
require 'ezmq/api'

module EZMQ
  class << self
    # The version of the 0MQ library as an array of [Major, minor, patch].
    # @return [Array<<Integer>>]
    def zmq_version_nums
      pointers = []
      3.times {pointers << FFI::MemoryPointer.new(:int)}
      API.zmq_version *pointers
      nums = pointers.collect {|p| p.read_int}
      pointers.each {|p| p.free}
      nums
    end

    # The version of the 0MQ library. Not to be confused with the version
    # of the EZMQ gem.
    # @return [String]
    def zmq_version
      zmq_version_nums.join '.'
    end

  private
    def load_for_version(major, minor, patch)
      logger.info "Loading EZMQ for 0mq version #{major}.#{minor}.#{patch}"

      if major >= 3
        require 'ezmq/zmq3/ezmq'
      else
        raise RuntimeError, "EZMQ does not support ZeroMQ versions less than 3.x"
      end

      if major >= 4
        require 'ezmq/zmq4/ezmq'
      end
    end
  end

  load_for_version(*zmq_version_nums)
end
