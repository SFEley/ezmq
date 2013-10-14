module EZMQ
  describe Message do
    subject {described_class.new 'foo', 'bar'}

    it "can receive multiple strings when created" do
      expect(subject.parts).to include 'foo', 'bar'
    end

    it "can be created without content" do
      expect(described_class.new).to be_empty
    end

    it "stands in for an array" do
      expect([] + subject).to eq ['foo', 'bar']
    end

    it "stands in for a string" do
      expect("" + subject).to eq "foobar"
    end

    it "defaults to a binary string" do
      expect(subject.to_s.encoding).to eq Encoding::ASCII_8BIT
    end
  end
end
