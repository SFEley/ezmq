module EZMQ
  # Collects the new features and changes in usage patterns between 0mq 3.2.x
  # 0mq 4.0, and decorates the core classes with these changes via module
  # inclusion.  This should happen automatically when the {EZMQ} module is
  # required, based on the version string returned by the 0mq library.
  module Zmq4_0
    require_relative 'zmq4_0/api'
    require_relative 'zmq4_0/context'

    def self.included(target)
      API.extend API::Zmq4_0
      Context.include Context::Zmq4_0
    end
  end
end
