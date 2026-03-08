require "../../../spec_helper"

describe EasySubtitle::SrtParser do
  describe ".parse" do
    it "parses a valid SRT file" do
      blocks = EasySubtitle::SrtParser.parse(read_fixture("sample.srt"))
      blocks.size.should eq 3

      blocks[0].index.should eq 1
      blocks[0].start_time.to_s.should eq "00:00:01,000"
      blocks[0].end_time.to_s.should eq "00:00:04,000"
      blocks[0].lines.should eq ["Hello, world!"]

      blocks[1].index.should eq 2
      blocks[1].lines.should eq ["This is a sample subtitle file."]

      blocks[2].index.should eq 3
      blocks[2].lines.size.should eq 2
      blocks[2].lines[0].should eq "It contains three blocks"
      blocks[2].lines[1].should eq "for testing purposes."
    end

    it "handles malformed SRT gracefully" do
      blocks = EasySubtitle::SrtParser.parse(read_fixture("malformed.srt"))
      blocks.size.should eq 2
      blocks[0].index.should eq 1
      blocks[0].lines.should eq ["Hello"]
      blocks[1].index.should eq 4
      blocks[1].lines.should eq ["Valid block after bad ones."]
    end

    it "handles BOM" do
      content = "\uFEFF1\n00:00:01,000 --> 00:00:02,000\nHello"
      blocks = EasySubtitle::SrtParser.parse(content)
      blocks.size.should eq 1
      blocks[0].lines.should eq ["Hello"]
    end

    it "handles empty content" do
      blocks = EasySubtitle::SrtParser.parse("")
      blocks.size.should eq 0
    end
  end

  describe ".parse_file" do
    it "parses from file path" do
      blocks = EasySubtitle::SrtParser.parse_file(fixture("sample.srt"))
      blocks.size.should eq 3
    end
  end
end
