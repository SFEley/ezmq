# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
require 'timeout'

require 'ezmq'
$:.unshift File.join(File.dirname(__FILE__), 'support')

Process.setrlimit(:NOFILE, 4096)    # Don't run out of file handles
Thread.abort_on_exception = true

# Log testing activity if there's a log directory
logdir = File.join(File.dirname(__FILE__), '..', 'log')
if Dir.exist?(logdir)
  require 'logger'
  EZMQ.logger = Logger.new File.join(logdir, 'spec.log')
  EZMQ.logger.level = Logger::DEBUG
end
EZMQ.linger = 10


RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.around(:each) do |example|
    Timeout::timeout(10) {example.run}
  end
end
