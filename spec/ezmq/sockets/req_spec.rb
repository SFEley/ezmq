require 'spec_helper'
require 'ezmq/sockets/socket_shared'

module EZMQ
  describe REQ do

    let(:other) {REP.new :bind => :inproc}

    it_behaves_like "every socket"
    it_behaves_like "a sending socket"
    it_behaves_like "a receiving socket"

  end
end