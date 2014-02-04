require 'spec_helper'
module EZMQ
  describe EZMQ, :focus do
    it "has a global linger value by default" do
      expect(described_class.linger).to be > 0
    end

    describe "global context" do
      it "is always there when we need it" do
        expect(described_class.context).to be_an EZMQ::Context
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

      after {described_class.terminate!}
    end

    describe "::proxy method" do
      # Using DEALERs instead of PAIRs because they're more typical in a
      # context connection and termination sense.
      let(:context) {Context.new}
      let!(:front) {DEALER.new :context => context}
      let(:frontend) {DEALER.new :connect => front, :context => context}
      let!(:back) {DEALER.new :context => context}
      let(:backend) {DEALER.new :connect => back, :context => context}
      let(:captured) {DEALER.new :context => context}
      let(:capturer) {DEALER.new :connect => captured, :context => context}

      before do
        frontend.send "Test One"
        backend.send "Test Two"
        expect(front.receive).to eq "Test One"
        expect(back.receive).to eq "Test Two"
      end

      it "requires a frontend" do
        expect {described_class.proxy}.to raise_error ArgumentError
      end

      it "requires a backend" do
        expect {described_class.proxy frontend}.to raise_error ArgumentError
      end

      context "in its own thread" do
        def proxy_return
          unless @returned
            @returned = true
            context.terminate
            proxy_thread.join(1)
          end
        end

        let(:proxy) {described_class.proxy frontend, backend, capturer}
        let(:proxy_thread) {Thread.new {proxy}}

        before {proxy_thread.run and sleep 0.1}

        it "runs indefinitely" do
          expect(proxy_thread).to be_alive
          puts "Made it this far...."
        end

        it "passes from front to back" do
          front.send "Hello world!"
          expect(back.receive).to eq "Hello world!"
          puts "Made it this far again..."
        end

        it "eats the termination exception" do
          expect {proxy_return}.not_to raise_error
          puts "Made it this far yet again..."
        end

        after {proxy_return}
      end
    end

  end
end
