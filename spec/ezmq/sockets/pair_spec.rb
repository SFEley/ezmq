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

    it "falls back to Ruby #send when given a symbol" do
      expect(subject.send :kind_of?, Socket).to be_true
      expect(subject.send :instance_of?, Socket).to be_false
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

      it "chokes on invalid endpoints" do
        ['blah', 'invalid://thing.here', :foo, nil].each do |bad_endpoint|
          expect {subject.bind bad_endpoint}.to raise_error(InvalidEndpoint, /#{bad_endpoint}/)
        end
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

      it "can be given a local socket" do
        subject.connect bound
        expect(subject.connections).to include(endpoint)
      end

      it "creates an inproc transport if given a local socket without one" do
        this = described_class.new :bind => :tcp
        subject.connect this
        expect(this).to have(2).endpoints
        expect(subject.connections).to include(this.endpoints[1])
      end

      it "chokes on invalid endpoints" do
        ['blah', 'invalid://thing.here', :foo, nil].each do |bad_endpoint|
          expect {subject.connect bad_endpoint}.to raise_error(InvalidEndpoint, /#{bad_endpoint}/)
        end
      end
    end

    describe "sending" do
      let(:other) {PAIR.new :bind => :inproc}
      before do
        subject.connect other
      end

      it "can send a single-part message" do
        subject.send "Now is the time for all good men to come to the aid of their party!"
        other.receive.should eq "Now is the time for all good men to come to the aid of their party!"
      end

      it "can send a multi-part message" do
        subject.send "Hello", "World!"
        expect(other.receive).to include "Hello", "World!"
      end
    end

    describe "receiving" do
      let(:other) {PAIR.new :bind => :inproc}
      before do
        subject.connect other
      end


      it "can receive a single-part message" do
        other.send "Now is the time for all good men to come to the aid of their party!"
        expect(subject.receive).to eq "Now is the time for all good men to come to the aid of their party!"
      end

      it "can receive a multi-part message" do
        other.send "Hello", "World!"
        expect(subject.receive).to include "Hello", "World!"
      end
    end
  end
end
