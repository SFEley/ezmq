require 'spec_helper'
require 'ezmq/sockets/socket_shared'
require 'ezmq/sockets/subscriber_shared'

module EZMQ
  # XSUB socket in 3.2 has a default linger of 0 instead of -1
  describe XSUB, :default_linger => 0 do
    let(:other) {PUB.new :bind => :inproc}

    it_behaves_like "every socket"

    it_behaves_like "a receiving socket" do
      before do
        subject.connect other
        subject.subscribe ''
      end
    end

    it_behaves_like "a subscriber"
  end
end
