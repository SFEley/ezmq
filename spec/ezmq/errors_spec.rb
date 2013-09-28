module EZmq
  module Errors
    describe Errors do
      # Ensure everything in include/zmq.h gets set up
      TYPES = [
        :ENOTSUP, :EPROTONOSUPPORT, :ENOBUFS, :ENETDOWN, :EADDRINUSE,
        :EADDRNOTAVAIL, :ECONNREFUSED, :EINPROGRESS, :ENOTSOCK, :EMSGSIZE,
        :EAFNOSUPPORT, :ENETUNREACH, :ECONNABORTED, :ECONNRESET, :ENOTCONN,
        :ETIMEDOUT, :EHOSTUNREACH, :ENETRESET, :EFSM, :ENOCOMPATPROTO,
        :ETERM, :EMTHREAD
      ]

      TYPES.each do |this_type|
        if Errors.const_defined?(this_type)
          this_class = Errors.const_get(this_type)
          describe this_class do
            let(:described_class) {this_class}
            let(:class_basename) {described_class.to_s[/.*::(.*)$/, 1]}

            it "is a ZeroMQ error" do
              expect(subject).to be_a_kind_of(Errors::ZMQError)
            end

            it "knows its errno" do
              expect(subject.errno).to be > 0
            end

            it "responds to a ZMQ-specific errno" do
              expect(ERRNOS.any? {|k, v| k > HAUSNUMERO and v == described_class}).to be_true
            end

            it "can create an exception by errno" do
              expect(Errors.by_errno(subject.errno)).to be_a(described_class)
            end

            it "can raise the exception by errno" do
              expect {Errors.raise subject.errno}.to raise_error(described_class)
            end

            it "gets its description from ZeroMQ" do
              expect(subject.message).to eq API::zmq_strerror(subject.errno)
            end

            it "has a real description" do
              expect(subject.message).not_to match /Unknown error/
            end

            if Errno.constants.include?(this_type)
              let(:system_class) {Errno.const_get(class_basename)}

              it "responds to the standard system errno" do
                expect(Errors.errnos[system_class::Errno]).to eq described_class
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
            expect(Errors.const_defined? this_type).to be_true
          end
        end
      end

    end
  end
end
