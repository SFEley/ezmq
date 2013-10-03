require 'weakref'

module EZmq
  describe Context do

    it "can be created" do
      expect(subject).to be_a(Context)
    end

    it "holds the pointer to the 0mq context" do
      expect(subject.ptr).to be_a(FFI::Pointer)
    end

    describe "cleanup" do
      before(:each) do
        ObjectSpace.garbage_collect # Ensure pristine GC state every time
      end

      it "can close itself" do
        expect(API).to receive(:zmq_ctx_destroy).at_least(:once).and_call_original
        subject.destroy
      end

      it "destroys its 0mq context if garbage collected" do
        weakref, gc_counter = nil, 0
        expect(API).to receive(:zmq_ctx_destroy).at_least(:once).and_call_original
        begin
          weakref = WeakRef.new(Context.new)
        end
        ObjectSpace.garbage_collect while weakref.weakref_alive? && (gc_counter += 1) < 10
      end

      it "throws an error if used after destruction" do
        subject.destroy
        expect {subject.io_threads}.to raise_error(NoMethodError)
      end

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
        expect {subject.io_threads = -1}.to raise_error(Errors::EINVAL)
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
