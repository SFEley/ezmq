module EZMQ
  describe "exceptions" do
    # Ensure everything in include/zmq.h gets set up
    TYPES = [
      :ENOTSUP, :EPROTONOSUPPORT, :ENOBUFS, :ENETDOWN, :EADDRINUSE,
      :EADDRNOTAVAIL, :ECONNREFUSED, :EINPROGRESS, :ENOTSOCK, :EMSGSIZE,
      :EAFNOSUPPORT, :ENETUNREACH, :ECONNABORTED, :ECONNRESET, :ENOTCONN,
      :ETIMEDOUT, :EHOSTUNREACH, :ENETRESET, :EFSM, :ENOCOMPATPROTO,
      :ETERM, :EMTHREAD
    ]

    TYPES.each do |this_type|
      if EZMQ.const_defined?(this_type)
        this_class = EZMQ.const_get(this_type)
        describe this_class do
          let(:described_class) {this_class}
          let(:class_basename) {described_class.to_s[/.*::(.*)$/, 1]}

          it "is a ZeroMQ error" do
            expect(subject).to be_a_kind_of(ZMQError)
          end

          it "knows its errno" do
            expect(subject.errno).to be > 0
          end

          it "can create an exception by errno" do
            expect(ZMQError.for_errno(subject.errno)).to be_a described_class
          end

          it "gets its description from ZeroMQ" do
            expect(subject.message).to eq API::zmq_strerror(subject.errno).to_s
          end

          it "has a real description" do
            expect(subject.message).not_to match /Unknown error/
          end

          if Errno.constants.include?(this_type)
            let(:system_class) {Errno.const_get(class_basename)}

            it "responds to the standard system errno" do
              expect(ZMQError.for_errno(system_class::Errno)).to be_a described_class
            end

            it "uses the standard system errno canonically" do
              expect(subject.errno).to eq system_class::Errno
            end
          else
            it "uses the ZMQ-specific errno canonically" do
              expect(subject.errno).to be > HAUSNUMERO
            end
          end
        end
      else
        it "includes the #{this_type} error class" do
          expect(EZMQ.const_defined? this_type).to be_true
        end
      end
    end

    it "can retrieve errors by their number" do
      expect(ZMQError.for_errno(::Errno::EADDRNOTAVAIL::Errno)).to be_a EZMQ::EADDRNOTAVAIL
    end

    it "returns an Unknown exception if the number can't be found" do
      expect(ZMQError.for_errno(HAUSNUMERO - 10)).to be_a EZMQ::UnknownError
    end

  end
end
