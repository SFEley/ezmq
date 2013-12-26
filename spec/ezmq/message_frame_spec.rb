require 'weakref'

module EZMQ
  describe MessageFrame do
    let(:content) {"Now is the time for all good men to come to the aid of their party!"}

    describe "with no content or size" do
      it "calls zmq_msg_init on creation" do
        expect(API).to receive(:zmq_msg_init).and_call_original
        subject
      end

      it "has no size yet" do
        expect(subject.size).to eq 0
      end

      it "has no string value yet" do
        expect(subject.to_s).to eq ''
      end

      it "has no data yet" do
        expect(subject.data).to eq ''
      end

      it "can't set any content" do
        subject.data = 'Testing...'
        expect(subject.to_s).to eq ''
      end

      it "can't read anything by offset" do
        expect {subject[1]}.to raise_error(IndexError)
      end

      it "can't read any bytes" do
        expect {subject[0]}.to raise_error(RangeError)
      end

      it "can't set anything by offset" do
        expect {subject[1] = '?'}.to raise_error(IndexError)
      end

      it "knows there are no more messages" do
        expect(subject).not_to be_more
      end
    end

    describe "with a declared buffer size" do
      subject {described_class.new 10}

      it "calls msg_init_size on creation" do
        expect(API).to receive(:zmq_msg_init_size).and_call_original
        subject
      end

      it "knows its size" do
        expect(subject.size).to eq 10
      end

      it "has garbage in its data buffer" do
        expect(subject.data).to have(10).bytes
      end

      it "can set data up to the buffer size" do
        subject.data = "antidisestablishmentarianism"
        expect(subject.to_s).to eq 'antidisest'
      end

      it "is initialized with zeros" do
        expect(subject[2, 8]).to eq 0.chr * 8
      end

      it "can set by offset" do
        subject[4] = "Garbanzo"
        expect(subject.data).to match /^....Garban$/
      end

      it "can't read beyond its offset" do
        expect {subject[11]}.to raise_error(IndexError)
      end

      it "can read a substring" do
        subject[2] = "London Bridge"
        expect(subject[3, 4]).to eq 'ondo'
      end

      it "can't set beyond its offset" do
        expect {subject[11] = '?'}.to raise_error(IndexError)
      end

      it "can set from a substring" do
        subject[3, 4] = "DingDong"
        expect(subject.data).to match /^...Ding(?!Dong)/
      end

      it "sets from the whole value if no length is given" do
        subject[3] = "Thing"
        expect(subject.data).to match /^...Thing..$/
      end
    end

    describe "with provided content" do
      subject {described_class.new content}

      it "calls msg_init_size on creation" do
        expect(API).to receive(:zmq_msg_init_size).and_call_original
        subject
      end

      it "knows its size from what is given" do
        expect(subject.size).to eq 67
      end

      it "knows its string value" do
        expect(subject.to_s).to eq content
      end

      it "treats the content as binary encoded" do
        expect(subject.to_s.encoding).to eq Encoding::ASCII_8BIT
      end

      it "sees no difference between the string value and the data buffer" do
        expect(subject.data).to eq "#{subject}"
      end

      it "can overwrite the buffer" do
        subject.data = "The quick brown fox jumped over the lazy dog."
        expect(subject.to_s).to eq "The quick brown fox jumped over the lazy dog.\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
      end

    end

    describe "copying and moving" do
      let(:this) {described_class.new content}
      let(:that) {described_class.new}

      it "can copy TO another frame" do
        this.copy_to(that)
        expect(this.data).to eq content
        expect(that.data).to eq content
      end

      it "can copy FROM another frame" do
        that.copy_from(this)
        expect(this.data).to eq content
        expect(that.data).to eq content
      end

      it "copies when cloned" do
        other = this.clone
        expect(this.data).to eq content
        expect(other.data).to eq content
      end

      it "copies when duped" do
        other = this.dup
        expect(this.data).to eq content
        expect(other.data).to eq content
      end

      it "can move TO another frame" do
        this.move_to(that)
        expect(this.data).to be_empty
        expect(that.data).to eq content
      end

      it "can move FROM another frame" do
        that.move_from(this)
        expect(this.data).to be_empty
        expect(that.data).to eq content
      end

    end

    describe "cleanup" do

      before(:each) do
        ObjectSpace.garbage_collect # Ensure pristine GC state every time
      end

      it "can close itself" do
        expect(API).to receive(:zmq_msg_close).at_least(:once).and_call_original
        subject.close
      end

      it "closes itself if garbage collected" do
        weakref, gc_counter = nil, 0
        expect(API).to receive(:zmq_msg_close).at_least(:once).and_call_original
        begin
          weakref = WeakRef.new(described_class.new)
        end
        ObjectSpace.garbage_collect while weakref.weakref_alive? && (gc_counter += 1) < 10
      end

      it "returns a null pointer if cast after closing" do
        subject.close
        expect(subject.to_ptr).to be_null
      end

    end

  end
end
