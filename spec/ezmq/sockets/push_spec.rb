require 'spec_helper'
require 'ezmq/sockets/socket_shared'

module EZMQ
  describe PUSH do
    let(:other) {PULL.new :bind => :inproc}

    it_behaves_like "every socket"

    it_behaves_like "a send-only socket" do
      before do
        subject.connect other
      end
    end

  end
end
