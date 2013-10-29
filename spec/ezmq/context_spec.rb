require 'weakref'

module EZMQ
  describe EZMQ, "global context" do
    before {EZMQ.terminate!}

    it "has a global context" do
      expect(described_class.context).to be_a Context
    end

    it "returns the same context between calls" do
      expect(described_class.context).to eq described_class.context
    end

    it "can be terminated" do
      first = described_class.context
      described_class.terminate!
      expect(described_class.context).not_to eq first
    end

    it "closes itself when terminated" do
      expect(described_class.context).to receive(:terminate).and_call_original
      described_class.terminate!
    end

  end

  describe Context do

    it "can be created" do
      expect(subject).to be_a(Context)
    end

    it "can be treated as a pointer to the 0MQ context" do
      expect(subject.to_ptr).to be_a(Fiddle::Pointer)
    end

    it "raises an exception if it can't get a context" do
      expect(API).to receive(:zmq_ctx_new).and_return(Fiddle::NULL)
      allow(Fiddle).to receive(:last_error).and_return(ENOTSUP::Errno)

      expect {subject}.to raise_error(ENOTSUP)
    end

    it "raises an exception if used after the 0MQ context is terminated" do
      subject.destroy
      expect {subject.io_threads}.to raise_error(ContextClosed)
    end



    describe "cleanup" do
      before(:each) do
        ObjectSpace.garbage_collect # Ensure pristine GC state every time
      end

      it "can close itself" do
        expect(API).to receive(:zmq_ctx_destroy).at_least(:once).and_call_original
        subject.terminate
      end

      it "destroys its 0MQ context if garbage collected" do
        weakref, gc_counter = nil, 0
        expect(API).to receive(:zmq_ctx_destroy).at_least(:once).and_call_original
        begin
          weakref = WeakRef.new(Context.new)
        end
        ObjectSpace.garbage_collect while weakref.weakref_alive? && (gc_counter += 1) < 10
      end

      it "returns a null pointer if cast after closing" do
        subject.terminate
        expect(subject.to_ptr).to be_null
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
        expect {subject.io_threads = -1}.to raise_error(EZMQ::EINVAL)
      end

      it "knows its socket maximum" do
        expect(subject.max_sockets).to eq 1024
      end

      it "can set its socket maximum" do
        subject.max_sockets = 50
        expect(subject.max_sockets).to eq 50
      end

      it "can set the thread count on creation" do
        this = described_class.new io_threads: 5
        expect(this.io_threads).to eq 5
      end

      it "can set the socket maximum on creation" do
        this = described_class.new max_sockets: 300
        expect(this.max_sockets).to eq 300
      end
    end

    describe "socket list" do

      let(:socket) {double('Socket')}

      it "begins empty" do
        expect(subject.sockets).to be_empty
      end

      it "can be added to" do
        expect {subject << socket}.to change {subject.sockets.count}.by(1)
      end

      it "can be removed" do
        subject << socket
        expect {subject.remove(socket)}.to change {subject.sockets.count}.by(-1)
      end

      it "closes out when the context is finished" do
        subject << socket
        expect(socket).to receive(:close)
        subject.terminate
      end

    end

  end
end
