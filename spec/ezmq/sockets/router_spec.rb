require 'spec_helper'
require 'ezmq/sockets/socket_shared'

module EZMQ
  describe ROUTER do
    let(:other) {REQ.new :bind => :inproc}

    it_behaves_like "every socket"

    it "assigns a random identity when the sender hasn't set one yet" do
      other.connect subject
      other.identity = 'toolate'
      other.send "foo"
      received = subject.receive
      expect(received.shift).not_to eq 'toolate'
      expect(received).to eq ['', 'foo']
    end

    it "uses the given identity if the sender has set one" do
      other.identity = 'myself'
      other.connect subject
      other.send "foo"
      expect(subject.receive).to eq ['myself', '', 'foo']
    end

    it_behaves_like "a sending socket" do
      let(:other) {REQ.new :bind => :inproc, :identity => 'myself'}
      let(:single_received) {"Now is the time for all good men to come to the aid of their party!"}
      let(:multi_received) {%w[Hello World!]}
      let(:single_sent) {['myself', '', single_received]}
      let(:multi_sent) {['myself', ''] + multi_received}

      before do
        other.send "request"
        subject.receive
      end
    end

    it_behaves_like "a receiving socket" do
      let(:other) {REQ.new :bind => :inproc, :identity => 'myself'}
      let(:single_received) {['myself', '', single_sent]}
      let(:multi_received) {['myself', ''] + multi_sent}
    end

    it "can get and set whether to fail on unreachable destinations" do
      expect(subject).not_to be_fail_on_unreachable
      subject.fail_on_unreachable = true
      expect(subject).to be_fail_on_unreachable
    end

  end
end
