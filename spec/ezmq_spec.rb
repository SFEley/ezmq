module EZMQ
  describe EZMQ do
    it "has a global linger value by default" do
      expect(EZMQ.linger).to be > 0
    end

    describe "global context" do
      before {EZMQ.terminate!}

      it "is always there when we need it" do
        expect(described_class.context).to be_a Context
      end

      it "returns the same context between calls" do
        expect(described_class.context).to eq described_class.context
      end

      it "can be terminated" do
        first = described_class.context
        described_class.terminate!
        expect(described_class.context).not_to eq first
      end

      it "closes itself when terminated" do
        expect(described_class.context).to receive(:terminate).and_call_original
        described_class.terminate!
      end

    end

  end

end
