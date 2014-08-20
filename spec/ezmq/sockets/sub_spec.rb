require 'spec_helper'
require 'ezmq/sockets/socket_shared'
require 'ezmq/sockets/subscriber_shared'

module EZMQ
  # SUB socket in 3.2 has a default linger of 0 instead of -1
  xdescribe SUB, :default_linger => 0 do
    let(:other) {PUB.new :bind => :inproc}

    it_behaves_like "every socket"

    # it "defaults LINGER to zero if not given by an option nor global value" do
    #   global_linger = EZMQ.linger
    #   EZMQ.linger = nil
    #   expect(subject.linger).to eq 0
    #   EZMQ.linger = global_linger
    # end


    it_behaves_like "a receive-only socket" do
      before do
        subject.connect other
        subject.subscribe ''
      end
    end

    it_behaves_like "a subscriber"

  end
end
