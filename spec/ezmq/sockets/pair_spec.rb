module EZMQ
  describe PAIR, :focus do
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
      let(:endpoint) {"inproc://test_#{rand(1_000_000)}"}

      it "has no endpoints on creation" do
        expect(subject.endpoints).to be_empty
      end

      it "can be bound to an endpoint" do
        subject.bind endpoint
        expect(subject.endpoints).to include endpoint
      end

      it "can be bound to multiple endpoints" do
        subject.bind endpoint, endpoint.succ
        expect(subject.endpoints).to include endpoint, endpoint.succ
      end

      it "knows the last endpoint bound" do
        subject.bind endpoint
        expect(subject.last_endpoint).to eq endpoint
      end

      it "returns the last endpoint when asked for just one" do
        subject.bind endpoint, endpoint.succ
        expect(subject.endpoint).to eq endpoint.succ
      end

      it "can bind with :inproc and make a name for itself" do
        subject.bind :inproc
        expect(subject.endpoints.first).to match %r[^inproc://#{subject.type}-\d+$]
      end

      it "can bind with :ipc and find its path" do
        subject.bind :ipc
        expect(File.exists?(subject.endpoints.first[%r{ipc://(.*)}, 1])).to be_true
      end

      it "can bind with :tcp and make it to port" do
        subject.bind :tcp
        expect(subject.endpoints.first).to match %r[^tcp://0.0.0.0:\d{4,5}]
      end

      it "can be bound on creation" do
        this = described_class.new bind: ["inproc://thisone"]
        expect(this.endpoint).to match %r[^inproc://]
      end

      it "can be bound to more than one endpoint on creation" do
        this = described_class.new bind: [:inproc, :tcp]
        expect(this).to have(2).endpoints
      end
    end

    describe "connecting" do
      let(:bound) {described_class.new :bind => :inproc}
      let!(:endpoint) {bound.endpoint}

      it "has no connections on creation" do
        expect(subject.connections).to be_empty
      end

      it "can be connected to an endpoint" do
        subject.connect endpoint
        expect(subject.connections).to include(endpoint)
      end

      it "can be connected on creation" do
        this = described_class.new :connect => endpoint
        expect(this.connections).to include(endpoint)
      end
    end

    describe "sending and receiving" do
      let!(:left) {described_class.new :bind => :inproc}
      let!(:right) {described_class.new :connect => left.endpoint}

      it "can send a single-part message" do
        left.send "Now is the time for all good men to come to the aid of their party!"
        right.receive.should eq "Now is the time for all good men to come to the aid of their party!"
      end

    end
  end
end
