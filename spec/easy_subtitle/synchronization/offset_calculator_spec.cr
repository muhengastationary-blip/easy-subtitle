require "../../spec_helper"

describe EasySubtitle::OffsetCalculator do
  describe ".first_timestamp" do
    it "extracts first timestamp from SRT" do
      ts = EasySubtitle::OffsetCalculator.first_timestamp(fixture("sample.srt"))
      ts.should eq 1.0
    end

    it "returns 0 for empty file" do
      path = "/tmp/easy-subtitle-empty.srt"
      File.write(path, "")
      ts = EasySubtitle::OffsetCalculator.first_timestamp(path)
      ts.should eq 0.0
    ensure
      File.delete(path) if path && File.exists?(path)
    end
  end

  describe ".calculate" do
    it "calculates offset between original and shifted" do
      offset = EasySubtitle::OffsetCalculator.calculate(
        fixture("sample.srt"),
        fixture("sample_shifted.srt")
      )
      offset.should eq 2.5
    end

    it "returns 0 for identical files" do
      offset = EasySubtitle::OffsetCalculator.calculate(
        fixture("sample.srt"),
        fixture("sample.srt")
      )
      offset.should eq 0.0
    end
  end
end
