module EZMQ
  describe PAIR do
    it "defaults to the global context" do
      expect(subject.context).to eq EZMQ.context
    end

    it "can take a custom context" do
      my_context = Context.new
      this = described_class.new context: my_context
      expect(this.context).to eq my_context
    end

    it "attaches to the context" do
      expect(subject.context.sockets).to include(subject)
    end

    it "has an associated socket object" do
      expect(subject.ptr).to be_a(FFI::Pointer)
    end

    it "can be treated as a pointer to the socket" do
      expect(subject.to_ptr).to be_a(FFI::Pointer)
    end


    describe "binding" do
      it "has no endpoints on creation" do
        expect(subject.endpoints).to be_empty
      end

      it "can be bound to an endpoint" do
        subject.bind ep = "inproc://test_#{rand(1_000_000)}"
        expect(subject.endpoints).to include ep
      end

      it "knows the last endpoint bound" do
        subject.bind ep = "inproc://test_#{rand(1_000_000)}"
        expect(subject.last_endpoint).to eq ep
      end

      it "can bind with :inproc and make a name for itself" do
        subject.bind :inproc
        puts subject.endpoints
        expect(subject.endpoints.first).to match %r[^inproc://#{subject.type}-\d+$]
      end

      it "can bind with :ipc and find its path" do
        subject.bind :ipc
        puts subject.endpoints.first
        expect(File.exists?(subject.endpoints.first[%r{ipc://(.*)}, 1])).to be_true
      end

      it "can bind with :tcp and make it to port" do
        subject.bind :tcp
        puts subject.endpoints.first
        expect(subject.endpoints.first).to match %r[^tcp://0.0.0.0:\d{4,5}]
      end
    end

    describe "connecting" do


    end
  end
end
