require "../../../spec_helper"

describe EasySubtitle::SrtWriter do
  describe ".to_s" do
    it "writes blocks to SRT format" do
      blocks = [
        EasySubtitle::Block.new(
          index: 1,
          start_time: EasySubtitle::Timestamp.new(0, 0, 1, 0),
          end_time: EasySubtitle::Timestamp.new(0, 0, 4, 0),
          lines: ["Hello, world!"]
        ),
        EasySubtitle::Block.new(
          index: 2,
          start_time: EasySubtitle::Timestamp.new(0, 0, 5, 500),
          end_time: EasySubtitle::Timestamp.new(0, 0, 8, 200),
          lines: ["Second line."]
        ),
      ]

      output = EasySubtitle::SrtWriter.to_s(blocks)
      output.should contain "1\n00:00:01,000 --> 00:00:04,000\nHello, world!"
      output.should contain "2\n00:00:05,500 --> 00:00:08,200\nSecond line."
    end

    it "round-trips parsed SRT" do
      original_blocks = EasySubtitle::SrtParser.parse(read_fixture("sample.srt"))
      written = EasySubtitle::SrtWriter.to_s(original_blocks)
      reparsed = EasySubtitle::SrtParser.parse(written)

      reparsed.size.should eq original_blocks.size
      reparsed.each_with_index do |block, i|
        block.index.should eq original_blocks[i].index
        block.start_time.should eq original_blocks[i].start_time
        block.end_time.should eq original_blocks[i].end_time
        block.lines.should eq original_blocks[i].lines
      end
    end
  end

  describe ".reindex" do
    it "reindexes blocks starting from 1" do
      blocks = [
        EasySubtitle::Block.new(index: 5, start_time: EasySubtitle::Timestamp.new(0, 0, 1, 0), end_time: EasySubtitle::Timestamp.new(0, 0, 2, 0), lines: ["A"]),
        EasySubtitle::Block.new(index: 10, start_time: EasySubtitle::Timestamp.new(0, 0, 3, 0), end_time: EasySubtitle::Timestamp.new(0, 0, 4, 0), lines: ["B"]),
      ]

      reindexed = EasySubtitle::SrtWriter.reindex(blocks)
      reindexed[0].index.should eq 1
      reindexed[1].index.should eq 2
    end
  end
end
