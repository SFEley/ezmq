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


    describe "lingering" do
      # Weirdly, SUB and XSUB sockets have a default LINGER option of 0.
      # Everything else defaults to -1. Don't know what's up with that, but
      # we account for it by making the default configurable per class.
      let(:default_linger) {example.metadata.fetch :default_linger, -1}

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

      it "uses the socket default if not given by an option nor global value" do
        EZMQ.linger = nil
        expect(subject.linger).to eq default_linger
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
      it "can get and set the identity" do
        expect(subject.identity).to eq ''
        subject.identity = uniq = "foo-#{rand}"
        expect(subject.identity).to eq uniq
      end

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

      it "can get and set the thread affinity" do
        expect(subject.affinity).to eq 0
        expect {subject.affinity=4}.to change {subject.affinity}.by 4
      end

      it "can get and set the multicast data rate" do
        expect(subject.rate).to eq 100
        expect {subject.rate=180}.to change {subject.rate}.by 80
      end

      it "can get and set the multicast recovery interval" do
        expect(subject.recovery_interval).to eq 10_000
        expect {subject.recovery_interval=1500}.to change {subject.recovery_interval}.by -8500
      end

      it "can get and set the send buffer size" do
        expect(subject.send_buffer).to eq 0
        expect {subject.send_buffer=2400}.to change {subject.send_buffer}.by 2400
      end

      it "can get and set the receive buffer size" do
        expect(subject.receive_buffer).to eq 0
        expect {subject.receive_buffer=2400}.to change {subject.receive_buffer}.by 2400
      end

      it "can get and set the minimum reconnect interval" do
        expect(subject.reconnect_interval).to eq 100
        expect {subject.reconnect_interval=600}.to change {subject.reconnect_interval}.by 500
      end

      it "can get and set the maximum reconnect interval" do
        expect(subject.reconnect_interval_max).to eq 0
        expect {subject.reconnect_interval_max=300000}.to change {subject.reconnect_interval_max}.by 300000
      end

      it "can get and set the maximum message size" do
        expect(subject.max_message_size).to eq -1
        expect {subject.max_message_size=1024}.to change {subject.max_message_size}.by 1025
      end

      it "can get and set the multicast hops" do
        expect(subject.multicast_hops).to eq 1
        expect {subject.multicast_hops=10}.to change {subject.multicast_hops}.by 9
      end

      it "can get and set whether the socket is IPV4 only" do
        expect(subject.ipv4_only).to eq 1
        expect(subject).to be_ipv4_only
        subject.ipv4_only = false
        expect(subject.ipv4_only).to eq 0
        expect(subject).not_to be_ipv4_only
      end

      it "can get and set whether to delay attaching on connect" do
        expect(subject.delay_attach_on_connect).to eq 0
        expect(subject).not_to be_delay_attach_on_connect
        subject.delay_attach_on_connect = true
        expect(subject.delay_attach_on_connect).to eq 1
        expect(subject).to be_delay_attach_on_connect
      end

      it "can get and set TCP keepalive" do
        expect(subject.tcp_keepalive).to eq -1
        expect {subject.tcp_keepalive=1}.to change {subject.tcp_keepalive}.by 2
      end

      it "can get and set TCP keepalive idle time" do
        expect(subject.tcp_keepalive_idle).to eq -1
        expect {subject.tcp_keepalive_idle=600}.to change {subject.tcp_keepalive_idle}.by 601
      end

      it "can get and set the TCP keepalive interval" do
        expect(subject.tcp_keepalive_interval).to eq -1
        expect {subject.tcp_keepalive_interval=10}.to change {subject.tcp_keepalive_interval}.by 11
      end

      it "can get and set the TCP keepalive count" do
        expect(subject.tcp_keepalive_count).to eq -1
        expect {subject.tcp_keepalive_count=20}.to change {subject.tcp_keepalive_count}.by 21
      end

      it "can get, set, and clear TCP accept filters" do
        expect(subject.tcp_accept_filters).to be_empty
        subject.tcp_accept_filter "192.168.0.0/16"
        expect(subject.tcp_accept_filters).to eq ['192.168.0.0/16']
        subject.tcp_accept_filter nil
        expect(subject.tcp_accept_filters).to be_empty
      end

      it "can get the internal file descriptor" do
        expect(subject.file_descriptor).to be > 0
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
        this = described_class.new bind: ["inproc://this_#{described_class}"]
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

      describe "and unbinding" do

        before do
          subject.bind endpoint
          expect(subject.last_endpoint).to eq endpoint
        end

        it "succeeds" do
          pending "until the unbinding bug in ZeroMQ 3.x is fixed"
          expect {subject.unbind endpoint}.not_to raise_error
        end

        it "clears the endpoint from the list" do
          pending "until the unbinding bug in ZeroMQ 3.x is fixed"
          subject.unbind endpoint
          expect(subject.endpoints).to be_empty
        end

        it "fails if given a bad endpoint" do
          pending "until the unbinding bug in ZeroMQ 3.x is fixed"
          expect {subject.unbind endpoint.succ}.to raise_error(InvalidEndpoint)
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

      describe "and disconnecting" do
        before do
          subject.connect bound
          expect(subject.connections).to include endpoint
        end

        it "succeeds" do
          expect {subject.disconnect endpoint}.not_to raise_error
        end

        it "clears the endpoint from the list" do
          subject.disconnect endpoint
          expect(subject.connections).to be_empty
        end

        it "fails if given a bad endpoint" do
          expect {subject.disconnect endpoint.succ}.to raise_error(ENOENT)
        end
      end
    end


    describe "on cleanup" do
      it "can close itself" do
        expect(API).to receive(:zmq_close).with(subject.ptr).and_call_original
        subject.close
      end

      it "closes if its context is shut down" do
        allow(API).to receive(:zmq_close).and_call_original
        expect(API).to receive(:zmq_close).with(subject.ptr).and_call_original
        subject.context.terminate
      end

      it "returns a null pointer if cast after closing" do
        subject.close
        expect(subject.to_ptr).to be_null
      end

    end

  end

  shared_context "message delivery" do
    let(:single_sent) {"Now is the time for all good men to come to the aid of their party!"}
    let(:single_received) {single_sent}
    let(:multi_sent) {%w[Hello World!]}
    let(:multi_received) {multi_sent}
    before {subject.connect other}
  end

end
