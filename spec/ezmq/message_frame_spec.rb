module EZMQ
  describe MessageFrame do
    it "calls zmq_msg_init on creation" do
      expect(API).to receive(:zmq_msg_init)
      subject
    end

  end
end
