require 'spec_helper'
require 'ezmq/sockets/socket_shared'

module EZMQ
  describe PUB do
    let(:other) {SUB.new :subscribe => ''}

    it_behaves_like "every socket"
    it_behaves_like "a send-only socket" do
      before do
        other.connect subject
      end
    end

  end
end
