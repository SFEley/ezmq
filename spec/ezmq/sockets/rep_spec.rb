require 'spec_helper'
require 'ezmq/sockets/socket_shared'

module EZMQ
  describe REP do

    let(:other) {REQ.new :bind => :inproc}

    it_behaves_like "every socket"
    it_behaves_like "a receiving socket"
    it_behaves_like "a sending socket" do
      before do
        other.send "Obligatory request message"
        subject.receive
      end
    end

    describe "#on_request method" do
      before {subject.connect other}
      it "handles single-part messages" do
        other.send "Foo!"
        subject.on_receive {|msg| "You said '#{msg}'"}
        other.receive.should eq "You said 'Foo!'"
      end

    end
  end
end

