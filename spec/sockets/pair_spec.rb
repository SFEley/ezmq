require 'spec_helper'
require_relative 'socket_shared'

module EZMQ
  describe PAIR do

    let(:other) {PAIR.new :bind => :inproc}

    it_behaves_like "every socket"
    it_behaves_like "a sending socket"
    it_behaves_like "a receiving socket"


    describe "pair creation" do

      it "creates two sockets" do
        expect(described_class.new_pair).to have(2).sockets
      end

      it "passes options to both sockets" do
        left, right = described_class.new_pair linger: 500
        expect(left.linger).to eq 500
        expect(right.linger).to eq 500
      end

      it "gives the :left and :right names to the sockets" do
        left, right = described_class.new_pair left: 'ThingOne', right: 'ThingTwo'
        expect(left.name).to eq 'ThingOne'
        expect(right.name).to eq 'ThingTwo'
      end

      it "binds the left socket" do
        left, right = described_class.new_pair
        expect(left.endpoints).to include "inproc://#{left.name}"
      end

      it "connects the right socket" do
        left, right = described_class.new_pair
        expect(right.connections).to include "inproc://#{left.name}"
      end

    end

  end
end
