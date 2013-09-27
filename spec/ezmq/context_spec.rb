module EZmq
  describe Context do
    it "can be created" do
      expect(subject).to be_a(Context)
    end

    it "holds the pointer to the 0mq context" do
      expect(subject.ptr).to be_a(FFI::Pointer)
    end

    it "can clean itself up" do
      expect(subject.destroy).to eq 0
    end
  end
end
