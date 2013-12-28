require 'spec_helper'
require 'ezmq/sockets/socket_shared'

module EZMQ
  describe XPUB do
    let(:other) {SUB.new}

    it_behaves_like "every socket"
    it_behaves_like "a sending socket" do
      before do
        other.subscribe ''
        other.connect subject
      end
    end

    describe "subscription messaging" do
      let(:received) {[]}

      before do
        other.subscribe 'aa'
        other.connect subject
        other.subscribe 'ba'
        other.subscribe 'cba'
        3.times {received << subject.receive}
      end

      it "receives a notice on new subscriptions" do
        expect(received).to eq %W[\x01aa \x01ba \x01cba]
      end

      it "receives a notice on unsubscriptions" do
        other.unsubscribe 'ba'
        received << subject.receive
        expect(received.last).to eq "\x00ba"
      end

      it "doesn't get a notice on invalid unsubscriptions" do
        other.unsubscribe 'qq', 'ba'
        received << subject.receive
        expect(received).to include "\x00ba"
        expect(received).not_to include "\x00qq"
      end

      it "doesn't get a notice on duplicate subscriptions when not verbose" do
        other.subscribe 'aa', 'dcba'
        received << subject.receive
        expect(received.last).to eq "\x01dcba"
      end

      it "sends a notice on duplicate subscriptions when verbose" do
        subject.verbose = true
        other.subscribe 'aa', 'dcba'
        received << subject.receive
        expect(received.last).to eq "\x01aa"
      end

      it "processes subscriptions whether explicitly received or not" do
        other.subscribe 'dcba'
        subject.send 'aaaa'
        subject.send 'qqqq'
        subject.send 'dcba'
        expect(other.receive).to eq 'aaaa'
        expect(other.receive).to eq 'dcba'
      end







    end

  end
end
