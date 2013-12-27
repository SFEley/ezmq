require 'spec_helper'
require 'ezmq/sockets/socket_shared'

module EZMQ
  describe REQ do

    let(:other) {REP.new :bind => :inproc}

    it_behaves_like "every socket"
    it_behaves_like "a sending socket"
    it_behaves_like "a receiving socket" do
      before do
        subject.send "Obligatory request message"
        other.receive
      end
    end

    describe "#request method" do
      before do
        @rep_thread = Thread.new do
          rep = REP.new :bind => :inproc, :linger => 0.1
          Thread.current[:endpoint] = rep.last_endpoint
          rep.on_request {|msg| msg.map {|part| part.upcase}}
        end
        sleep 0.01 until @rep_thread[:endpoint]
        subject.connect @rep_thread[:endpoint]
      end

      it "can send a single-part message" do
        expect(subject.request 'foo').to eq 'FOO'
      end

      it "can send a multi-part message" do
        expect(subject.request 'hello', 'world').to eq ['HELLO', 'WORLD']
      end

      after do
        @rep_thread.join(2) or begin
          puts "Timed out; killing reply thread"
          @rep_thread.kill
        end
      end
    end

  end
end
