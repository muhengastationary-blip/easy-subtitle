require "../../../spec_helper"

describe EasySubtitle::SrtCleaner do
  describe ".clean" do
    it "removes ad blocks" do
      blocks = EasySubtitle::SrtParser.parse(read_fixture("sample_with_ads.srt"))
      cleaned = EasySubtitle::SrtCleaner.clean(blocks)

      # Should remove blocks 2 (OpenSubtitles), 4 (VIP member), 6 (telesubtitles)
      cleaned.size.should eq 4
      cleaned.none? { |b| b.content.includes?("OpenSubtitles") }.should be_true
      cleaned.none? { |b| b.content.includes?("VIP member") }.should be_true
      cleaned.none? { |b| b.content.includes?("telesubtitles") }.should be_true
    end

    it "preserves real content" do
      blocks = EasySubtitle::SrtParser.parse(read_fixture("sample_with_ads.srt"))
      cleaned = EasySubtitle::SrtCleaner.clean(blocks)

      cleaned.any? { |b| b.content.includes?("Hello, world!") }.should be_true
      cleaned.any? { |b| b.content.includes?("real content") }.should be_true
      cleaned.any? { |b| b.content.includes?("Another real subtitle") }.should be_true
      cleaned.any? { |b| b.content.includes?("Final real content") }.should be_true
    end

    it "reindexes after cleaning" do
      blocks = EasySubtitle::SrtParser.parse(read_fixture("sample_with_ads.srt"))
      cleaned = EasySubtitle::SrtCleaner.clean(blocks)

      cleaned.each_with_index do |block, i|
        block.index.should eq i + 1
      end
    end
  end

  describe ".ad_block?" do
    it "detects OpenSubtitles ads" do
      block = EasySubtitle::Block.new(1,
        EasySubtitle::Timestamp.new(0, 0, 0, 0),
        EasySubtitle::Timestamp.new(0, 0, 1, 0),
        ["Downloaded from www.OpenSubtitles.org"]
      )
      EasySubtitle::SrtCleaner.ad_block?(block).should be_true
    end

    it "detects URL patterns" do
      block = EasySubtitle::Block.new(1,
        EasySubtitle::Timestamp.new(0, 0, 0, 0),
        EasySubtitle::Timestamp.new(0, 0, 1, 0),
        ["Visit https://example.com for more"]
      )
      EasySubtitle::SrtCleaner.ad_block?(block).should be_true
    end

    it "preserves regular content" do
      block = EasySubtitle::Block.new(1,
        EasySubtitle::Timestamp.new(0, 0, 0, 0),
        EasySubtitle::Timestamp.new(0, 0, 1, 0),
        ["Hello, this is normal dialogue."]
      )
      EasySubtitle::SrtCleaner.ad_block?(block).should be_false
    end
  end
end
