module EZMQ
  describe PAIR do
    it "defaults to the global context" do
      pending
      expect(subject.context).to eq EZMQ.context
    end
  end
end
