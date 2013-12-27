require 'weakref'
require 'ezmq/sockets/receive_shared'
require 'ezmq/sockets/send_shared'

module EZMQ
  shared_examples "every socket" do
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

    it "can set options on initialization" do
      this = described_class.new backlog: 17
      expect(this.backlog).to eq 17
    end


    describe "lingering", :linger_is_zero => false do
      before(:all) do
        @global_linger = EZMQ.linger
      end

      it "defaults to the global EZMQ value if given" do
        EZMQ.linger = 1900
        expect(subject.linger).to eq 1900
      end

      it "takes the initialization value if given" do
        this = described_class.new linger: 50
        expect(this.linger).to eq 50
      end

      it "defaults to infinite if not given by an option nor global value", :unless => :linger_is_zero do
        EZMQ.linger = nil
        expect(subject.linger).to eq -1
      end



      it "can be set for the socket" do
        subject.linger = 50
        expect(subject.linger).to eq 50
      end

      after(:each) do
        EZMQ.linger = @global_linger
      end
    end

    describe "options" do
      it "can get and set the backlog" do
        expect(subject.backlog).to eq 100
        expect {subject.backlog = 300}.to change {subject.backlog}.by 200
      end

      it "can get and set the sending high-water mark" do
        expect(subject.send_limit).to eq 1000
        expect {subject.send_limit = 500}.to change {subject.send_limit}.by -500
      end

      it "can get and set the receiving high-water mark" do
        expect(subject.receive_limit).to eq 1000
        expect {subject.receive_limit = 500}.to change {subject.receive_limit}.by -500
      end

      it "can get and set the send timeout" do
        expect(subject.send_timeout).to eq -1
        expect {subject.send_timeout = 2000}.to change {subject.send_timeout}.by 2001
      end

      it "can get and set the receive timeout" do
        expect(subject.receive_timeout).to eq -1
        expect {subject.receive_timeout = 2000}.to change {subject.receive_timeout}.by 2001
      end
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


    describe "cleanup" do
      before(:each) do
        ObjectSpace.garbage_collect # Ensure pristine GC state every time
      end

      it "can close itself" do
        expect(API).to receive(:zmq_close).at_least(:once).and_call_original
        subject.close
      end

      it "closes its 0MQ socket if garbage collected" do
        weakref, gc_counter = nil, 0
        expect(API).to receive(:zmq_close).at_least(:once).and_call_original
        begin
          weakref = WeakRef.new(described_class.new)
        end
        EZMQ.terminate!
        ObjectSpace.garbage_collect while weakref.weakref_alive? && (gc_counter += 1) < 10
      end

      it "returns a null pointer if cast after closing" do
        subject.close
        expect(subject.to_ptr).to be_null
      end

    end

  end

  shared_context "message delivery" do
    let(:single) {"Now is the time for all good men to come to the aid of their party!"}
    let(:multi) {%w[Hello World!]}
    before {subject.connect other}
  end

end
