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

    describe "options" do
      it "knows its thread count" do
        expect(subject.io_threads).to eq 1
      end

      it "can set its thread count" do
        subject.io_threads = 5
        expect(subject.io_threads).to eq 5
      end

      it "chokes if an invalid thread count is given" do
        pending
        expect {subject.io_threads = -1}.to raise_error
      end

      it "knows its socket maximum" do
        expect(subject.max_sockets).to eq 1024
      end

      it "can set its socket maximum" do
        subject.max_sockets = 50
        expect(subject.max_sockets).to eq 50
      end
    end
  end
end
