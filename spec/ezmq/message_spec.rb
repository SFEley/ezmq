module EZMQ
  describe Message do
    subject {described_class.new 'foo', 'bar'}

    it "can receive multiple strings when created" do
      expect(subject.parts).to include 'foo', 'bar'
    end

    it "can be created without content" do
      expect(Message.new).to be_empty
    end

    it "stands in for an array" do
      expect(subject[0]).to eq subject.parts[0]
    end
  end
end
