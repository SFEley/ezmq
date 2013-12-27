require 'ezmq/sockets/socket_shared'

module EZMQ
  shared_examples "a receiving socket" do
    include_context "message delivery"
    before do
      subject.receive_timeout = 1000
      other.send_timeout = 1000
    end

    it "can receive a single-part message" do
      other.send single
      expect(subject.receive).to eq single
    end

    it "can receive a multi-part message" do
      other.send *multi
      expect(subject.receive).to include "Hello", "World!"
    end

    it "can receive a multi-part message across multiple calls" do
      other.send *multi
      expect(subject.receive_part).to eq "Hello"
      expect(subject.receive_part).to eq "World!"
    end

    it "knows when there are more message parts" do
      other.send *multi
      expect(subject).not_to be_more
      subject.receive_part
      expect(subject).to be_more
      subject.receive_part
      expect(subject).not_to be_more
    end

    it "truncates when given a size" do
      other.send single
      expect(subject.receive size: 10).to eq "Now is the"
    end

    it "can receive into a message frame" do
      frame = MessageFrame.new
      other.send single
      subject.receive_into_frame(frame)
      expect(frame.to_s).to eq single
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
