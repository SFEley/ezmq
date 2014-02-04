require 'spec_helper'
require 'ezmq/sockets/socket_shared'

module EZMQ
  describe PULL, :focus do
    let(:other) {PUSH.new :bind => :inproc}

    it_behaves_like "every socket"
    it_behaves_like "a receive-only socket" do
      before do
        subject.connect other
      end
    end

  end
end
