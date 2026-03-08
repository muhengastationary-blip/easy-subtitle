require "../../../spec_helper"

describe EasySubtitle::Timestamp do
  describe ".parse" do
    it "parses valid timestamp" do
      ts = EasySubtitle::Timestamp.parse("01:23:45,678")
      ts.hours.should eq 1
      ts.minutes.should eq 23
      ts.seconds.should eq 45
      ts.milliseconds.should eq 678
    end

    it "parses zero timestamp" do
      ts = EasySubtitle::Timestamp.parse("00:00:00,000")
      ts.total_ms.should eq 0
    end

    it "parses with surrounding whitespace" do
      ts = EasySubtitle::Timestamp.parse("  01:02:03,004  ")
      ts.hours.should eq 1
      ts.minutes.should eq 2
      ts.seconds.should eq 3
      ts.milliseconds.should eq 4
    end

    it "raises on invalid format" do
      expect_raises(EasySubtitle::SrtParseError) do
        EasySubtitle::Timestamp.parse("not a timestamp")
      end
    end
  end

  describe "#total_seconds" do
    it "calculates total seconds" do
      ts = EasySubtitle::Timestamp.new(1, 30, 15, 500)
      ts.total_seconds.should eq 5415.5
    end
  end

  describe "#to_s" do
    it "formats timestamp correctly" do
      ts = EasySubtitle::Timestamp.new(1, 2, 3, 45)
      ts.to_s.should eq "01:02:03,045"
    end

    it "round-trips through parse" do
      original = "12:34:56,789"
      EasySubtitle::Timestamp.parse(original).to_s.should eq original
    end
  end

  describe "arithmetic" do
    it "adds timestamps" do
      a = EasySubtitle::Timestamp.new(0, 0, 1, 500)
      b = EasySubtitle::Timestamp.new(0, 0, 2, 300)
      (a + b).to_s.should eq "00:00:03,800"
    end

    it "subtracts timestamps" do
      a = EasySubtitle::Timestamp.new(0, 0, 5, 0)
      b = EasySubtitle::Timestamp.new(0, 0, 2, 500)
      (a - b).to_s.should eq "00:00:02,500"
    end
  end

  describe "comparison" do
    it "compares timestamps" do
      a = EasySubtitle::Timestamp.new(0, 0, 1, 0)
      b = EasySubtitle::Timestamp.new(0, 0, 2, 0)
      (a < b).should be_true
      (b > a).should be_true
      (a == a).should be_true
    end
  end

  describe "#abs" do
    it "returns absolute value" do
      a = EasySubtitle::Timestamp.new(0, 0, 5, 0)
      b = EasySubtitle::Timestamp.new(0, 0, 10, 0)
      (a - b).abs.to_s.should eq "00:00:05,000"
    end
  end
end
