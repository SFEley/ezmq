require 'ezmq/sockets/socket_shared'

module EZMQ
  shared_examples "a receiving socket" do
    before do
      subject.receive_timeout = 1000
      other.send_timeout = 1000
    end
    include_context "message delivery"

    it "can receive a single-part message" do
      other.send single_sent
      expect(subject.receive).to eq single_received
    end

    it "can receive a multi-part message" do
      other.send *multi_sent
      expect(subject.receive).to eq multi_received
    end

    it "can receive a multi-part message across multiple calls" do
      other.send *multi_sent
      multi_received.each {|part| expect(subject.receive_part).to eq part}
    end

    it "knows when there are more message parts" do
      other.send *multi_sent
      expect(subject).not_to be_more
      (multi_received.length - 1).times do
        subject.receive_part
        expect(subject).to be_more
      end
      subject.receive_part
      expect(subject).not_to be_more
    end

    it "truncates when given a size" do
      other.send single_sent
      expect(subject.receive size: 10).to eq Array(single_received).collect {|part| part[0,10]}
    end

    it "can receive into message frames" do
      frame = MessageFrame.new
      other.send *multi_sent
      multi_received.each do |part|
        subject.receive_into_frame(frame)
        expect(frame.to_s).to eq part
      end
    end

    it "knows when a message is ready to receive" do
      expect(subject).not_to be_receive_ready
      other.send single_sent
      expect(subject).to be_receive_ready
    end
  end

  shared_examples "a receive-only socket" do
    it_behaves_like "a receiving socket"

    it "cannot send" do
      expect {subject.send 'Foo!'}.to raise_error NoMethodError
    end

    it "cannot send from a message frame" do
      expect {subject.send_from_frame MessageFrame.new('Foo!')}.to raise_error NoMethodError
    end
  end
end
