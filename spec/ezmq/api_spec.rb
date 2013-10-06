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
      allow(described_class).to receive(:dummy).with(:break).and_return(-1)
      allow(FFI).to receive(:errno).and_return(EINVAL::Errno)
      # (I hate stubbing FFI like that, but throwing 0mq errors just to make this test fail seems dirtier.)
      expect {described_class.invoke :dummy, :break}.to raise_error(EINVAL)
    end
  end
end
