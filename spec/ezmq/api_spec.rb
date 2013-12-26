module EZMQ
  # Testing all of the 0mq bits is a waste of time. We're just testing the
  # calling functionality.
  describe API, '#invoke' do
    it "throws a straight up Ruby error when the method doesn't exist" do
      expect{described_class.invoke :foo, '5'}.to raise_error(NoMethodError)
    end

    it "calls the appropriate method with its parameters" do
      expect(described_class).to receive(:dummy).with(11).and_return(0)
      described_class.invoke :dummy, 11
    end

    it "returns the function call's value if it doesn't throw -1" do
      allow(described_class).to receive(:dummy).with('foo').and_return('bar!')
      expect(described_class.invoke :dummy, 'foo').to eq 'bar!'
    end

    it "raises the value of errno on a -1" do
      allow(described_class).to receive(:dummy).with(:numeric).and_return(-1)
      allow(FFI).to receive(:errno).and_return(EINVAL::Errno)

      # (I hate stubbing FFI like that, but throwing 0mq errors just to make this test fail seems dirtier.)
      expect {described_class.invoke :dummy, :numeric}.to raise_error(EINVAL)
    end


    it "raises the value of errno on a null pointer" do
      expect(described_class).to receive(:dummy).with(:pointer).and_return(FFI::Pointer::NULL)
      expect(FFI).to receive(:errno).and_return(EINVAL::Errno)

      # (I hate stubbing FFI like that, but throwing 0mq errors just to make this test fail seems dirtier.)
      expect {described_class.invoke :dummy, :pointer}.to raise_error(EINVAL)
    end
  end

  describe API, '#pointer_from' do
    let(:value) {"Garbanzø."}
    subject {described_class.pointer_from value}

    it "returns a pointer" do
      expect(subject).to be_an FFI::Pointer
    end

    it "is the right length" do
      expect(subject.size).to eq value.bytesize
    end

    it "contains the content given" do
      expect(subject.read_string).to eq value.force_encoding(Encoding::BINARY)
    end

    it "doesn't add nulls" do
      expect(subject.read_string subject.size).not_to include 0.chr
    end

    it "does keep nulls that were already there" do
      this = described_class.pointer_from "Garbanzø" + 0.chr
      expect(this.read_string(this.size).force_encoding(Encoding::UTF_8)).to end_with "ø\x00"
    end

  end
end
