require 'ezmq/sockets/socket_shared'

module EZMQ

  shared_examples "a sending socket" do
    include_context "message delivery"
    before do
      subject.send_timeout = 1000   # So failures don't block the spec run
      other.receive_timeout = 1000
    end

    it "can send a single-part message" do
      # Munged because ROUTER sockets never send single parts
      case single_sent
        when String then subject.send single_sent
        when Array then subject.send *single_sent
      end
      expect(other.receive).to eq single_received
    end

    it "can send a multi-part message" do
      subject.send *multi_sent
      expect(other.receive).to eq multi_received
    end

    it "can send a multi-part message across multiple calls" do
      multi_sent.each do |part|
        subject.send part, :more => (part != multi_sent.last)
      end
      expect(other.receive).to eq multi_received
    end

    # This example munged to hell only to handle the ROUTER socket
    it "can send into message frames" do
      multi_sent.each do |part|
        frame = MessageFrame.new part
        subject.send_from_frame frame, :more => (part != multi_sent.last)
      end
      expect(other.receive).to eq multi_received
    end
  end

  shared_examples "a send-only socket" do
    it_behaves_like "a sending socket"

    it "cannot receive" do
      expect {subject.receive}.to raise_error NoMethodError
    end

    it "cannot receive a message part" do
      expect {subject.receive_part}.to raise_error NoMethodError
    end

    it "cannot receive from a message frame" do
      expect {subject.receive_into_frame MessageFrame.new}.to raise_error NoMethodError
    end
  end
end
