module EZMQ
  describe Message do
    subject {described_class.new 'foo', 'bar'}

    describe "frames" do
      it "can receive multiple strings when created" do
        expect(subject.frames).to include 'foo', 'bar'
      end

      it "can be created without content" do
        expect(described_class.new).to be_empty
      end

      it "can have frames added" do
        expect(subject << 'baz').to eq %w(foo bar baz)
      end
    end

    describe "as an array" do
      it "stands in for an array" do
        expect([] + subject).to eq ['foo', 'bar']
      end

      it "can test equality against an array" do
          expect(subject).to eq %w(foo bar)
      end

      it "can be tested for equality against an array" do
        expect(['foo', 'bar']).to eq subject
      end

      it "can be compared against an array" do
        expect(subject <=> ['foo']).to eq 1
      end

      it "counts elements like an array" do
        expect(subject.count).to eq 2
      end
    end

    describe "as a string" do
      it "stands in for a string" do
        expect("" + subject).to eq "foobar"
      end

      it "defaults to a binary string" do
        expect(String.new(subject).encoding).to eq Encoding::ASCII_8BIT
      end

      it "can take another encoding at creation" do
        this = described_class.new 'foo', 'bar', :encoding => Encoding::ASCII
        expect(this.to_s.encoding).to eq Encoding::ASCII
      end

      it "can take another encoding after creation" do
        subject.encoding = Encoding::ASCII
        expect(subject.to_s.encoding).to eq Encoding::ASCII
      end

      it "can set the encoding for the class" do
        old_encoding = described_class.encoding
        described_class.encoding = Encoding::UTF_8
        expect(subject.to_s.encoding).to eq Encoding::UTF_8
        described_class.encoding = old_encoding
      end

      it "can match against regexes" do
        expect(subject).to match /ooba/
      end

      it "is equal against a string" do
        expect(subject).to eq 'foobar'
      end

      it "returns its size as the total string size" do
        expect(subject.size).to eq 6
      end

      it "returns its length as the total string length" do
        expect(subject.length).to eq 6
      end

      it "sizes by bytes, not characters" do
        subject.encoding = Encoding::UTF_8
        subject << "çåøß"
        expect(subject.size).to eq 14
        expect(subject.length).to eq 14
      end

      it "can be tested for equality against a string" do
        expect('foobar').to be == subject
      end

      it "can be compared against a string" do
        expect(subject).to be < 'foobarbaz'
      end

      it "can have a string compared against it" do
        expect('foob').to be < subject
      end

      it "can take another frame separator at creation" do
        expect(described_class.new 'foo', 'bar', :frame_separator => ':=:').to be =~  /foo:=:bar/
      end

      it "can take another frame separator after creation" do
        subject.frame_separator = '^^'
        expect(subject).to eq 'foo^^bar'
      end

      it "can set the frame separator for the class" do
        old_separator = described_class.frame_separator
        described_class.frame_separator = '#'
        expect(subject).to be == 'foo#bar'
        described_class.frame_separator = old_separator
      end
    end

  end
end
