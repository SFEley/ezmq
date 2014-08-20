module EZMQ

  shared_examples "a subscriber" do
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
      sleep 0.01   # Seems needed for XSUB unsubscription messages to go out
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
      subject {|example| described_class.new :subscribe => example.metadata[:subscribe]}

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
