require 'ezmq/sockets/socket_shared'

module EZMQ

  shared_examples "a sending socket" do
    include_context "message delivery"
    before do
      subject.send_timeout = 1000   # So failures don't block the spec run
      other.receive_timeout = 1000
    end

    it "can send a single-part message" do
      subject.send single
      expect(other.receive).to eq single
    end

    it "can send a multi-part message" do
      subject.send *multi
      expect(other.receive).to include "Hello", "World!"
    end

    it "can send a multi-part message across multiple calls" do
      subject.send multi[0], more: true
      subject.send multi[1]
      expect(other.receive).to eq "HelloWorld!"
    end

    it "can send into a message frame" do
      frame = MessageFrame.new single
      subject.send_from_frame(frame)
      expect(other.receive).to eq single
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
