require 'spec_helper'
require 'ezmq/sockets/socket_shared'

module EZMQ
  describe SUB, :linger_is_zero => true do
    let(:other) {PUB.new :bind => :inproc}

    # SUB socket in 3.2 has a default linger of 0 instead of -1
    it_behaves_like "every socket"

    it "defaults LINGER to zero if not given by an option nor global value" do
      global_linger = EZMQ.linger
      EZMQ.linger = nil
      expect(subject.linger).to eq 0
      EZMQ.linger = global_linger
    end


    it_behaves_like "a receive-only socket" do
      before do
        subject.connect other
        subject.subscribe ''
      end
    end

    describe "subscribing" do
      def send_messages
        other.send "aaaaa"
        other.send "bbaaa"
        other.send "aaabb"
      end

      let(:received) {[]}

      before do
        subject.connect other
      end

      it "can subscribe to all messages with an empty string" do
        subject.subscribe ''
        send_messages
        3.times {received << subject.receive}
        expect(received).to eq %w{aaaaa bbaaa aaabb}
      end

      it "can subscribe to all messages with no parameter" do
        subject.subscribe
        send_messages
        3.times {received << subject.receive}
        expect(received).to eq %w{aaaaa bbaaa aaabb}
      end

      it "can subscribe to a prefix filter" do
        subject.subscribe 'aaa'
        send_messages
        2.times {received << subject.receive}
        expect(received).to eq %w{aaaaa aaabb}
      end

      it "can subscribe to multiple filters" do
        subject.subscribe 'aaab', 'b'
        send_messages
        2.times {received << subject.receive}
        expect(received).to eq %w{bbaaa aaabb}
      end

      it "can unsubscribe" do
        subject.subscribe 'a', 'b'
        send_messages
        3.times {received << subject.receive}
        subject.unsubscribe 'a'
        send_messages
        received << subject.receive
        expect(received).to eq %w{aaaaa bbaaa aaabb bbaaa}
      end

      it "begins with no subscriptions" do
        expect(subject.subscriptions).to be_empty
      end

      it "tracks its subscriptions" do
        subject.subscribe 'aaab', 'b'
        expect(subject.subscriptions).to eq %w{aaab b}
      end

      it "tracks unsubscriptions" do
        subject.subscribe 'aaab', 'b'
        subject.unsubscribe 'aaab'
        expect(subject.subscriptions).to eq ['b']
      end

      describe "on initialization" do
        subject {described_class.new :subscribe => example.metadata[:subscribe]}

        before do
          send_messages
        end

        it "can subscribe to an empty filter", :subscribe => '' do
          3.times {received << subject.receive}
          expect(received).to eq %w{aaaaa bbaaa aaabb}
        end

        it "can subscribe to a single filter", :subscribe => 'a' do
          2.times {received << subject.receive}
          expect(received).to eq %w{aaaaa aaabb}
        end

        it "can subscribe to multiple filters", :subscribe => ['bb', 'aaab'] do
          2.times {received << subject.receive}
          expect(received).to eq %w{bbaaa aaabb}
        end


      end

    end

  end
end
