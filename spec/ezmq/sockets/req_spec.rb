require 'spec_helper'
require 'ezmq/sockets/socket_shared'

module EZMQ
  describe REQ, :focus do

    let(:other) {REP.new :bind => :inproc}

    it_behaves_like "every socket"
    it_behaves_like "a sending socket"
    it_behaves_like "a receiving socket" do
      before do
        subject.send "Obligatory request message"
        other.receive
      end
    end

    describe "#request method", :pending do
      before do
        Thread.abort_on_exception = true
        puts "Setting up the thread..."
        @rep_thread = Thread.new do
          puts "Creating REP socket..."
          rep = REP.new :bind => :inproc, :linger => 1
          puts "Socket created at #{rep.last_endpoint}"
          Thread.current[:endpoint] = rep.last_endpoint
          puts "Initiating request handler..."
          rep.on_request {|msg| msg.map {|part| part.upcase}}
          puts "Request received!"
        end
        sleep 1
        puts "Connecting to #{@rep_thread[:endpoint]}"
        sleep 3
        subject.connect @rep_thread[:endpoint]
      end

      it "can send a single-part message" do
        expect(subject.request 'foo').to eq 'FOO'
      end

      after do
        puts "Trying to close reply thread..."
        @rep_thread.join(2) or begin
          puts "Timed out; killing reply thread"
          @rep_thread.kill
        end
      end
    end

  end
end
