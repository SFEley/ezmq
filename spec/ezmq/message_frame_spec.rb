module EZMQ
  describe MessageFrame, :focus do
    it "calls zmq_msg_init on creation if no content or size are given" do
      expect(API).to receive(:zmq_msg_init)
      described_class.new
    end

  end
end
