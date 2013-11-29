require 'spec_helper'
require 'ezmq/sockets/socket_shared'

module EZMQ
  describe REP do

    let(:other) {REQ.new :bind => :inproc}

    it_behaves_like "every socket"
    it_behaves_like "a sending socket"
    it_behaves_like "a receiving socket"


  end
end

