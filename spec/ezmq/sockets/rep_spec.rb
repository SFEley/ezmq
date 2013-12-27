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
        subject.on_request {|msg| "You said '#{msg}'"}
        other.receive.should eq "You said 'Foo!'"
      end

      it "handles multi-part messages" do
        other.send "Foo", "Bar"
        subject.on_request {|msg| msg.map {|part| part.upcase}}
        other.receive.should eq ["FOO", "BAR"]
      end

      describe "with multiple requesters" do
        let(:other2) {REQ.new :bind => :inproc}
        before do
          subject.connect other2
          other2.send "foo", "bar"
          other.send "goo", "gar"
          2.times {subject.on_request {|msg| msg.map {|part| part.upcase}}}
        end

        it "sends the right reply to the right requester" do
          other.receive.should eq 'GOOGAR'
        end

        it "sends replies in order" do
          other2.receive.should eq %w[FOO BAR]
        end

      end
    end
  end
end

