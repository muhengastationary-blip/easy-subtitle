require "../../spec_helper"

describe EasySubtitle::Language do
  describe ".to_2" do
    it "converts 3-letter to 2-letter codes" do
      EasySubtitle::Language.to_2("eng").should eq "en"
      EasySubtitle::Language.to_2("dut").should eq "nl"
      EasySubtitle::Language.to_2("jpn").should eq "ja"
      EasySubtitle::Language.to_2("fre").should eq "fr"
      EasySubtitle::Language.to_2("ger").should eq "de"
    end

    it "handles alternate 3-letter codes" do
      EasySubtitle::Language.to_2("nld").should eq "nl"
      EasySubtitle::Language.to_2("fra").should eq "fr"
      EasySubtitle::Language.to_2("deu").should eq "de"
      EasySubtitle::Language.to_2("ces").should eq "cs"
    end

    it "returns code as-is if unknown" do
      EasySubtitle::Language.to_2("xx").should eq "xx"
      EasySubtitle::Language.to_2("en").should eq "en"
    end

    it "is case-insensitive" do
      EasySubtitle::Language.to_2("ENG").should eq "en"
      EasySubtitle::Language.to_2("Jpn").should eq "ja"
    end
  end

  describe ".to_3" do
    it "converts 2-letter to 3-letter codes" do
      EasySubtitle::Language.to_3("en").should eq "eng"
      EasySubtitle::Language.to_3("nl").should eq "dut"
      EasySubtitle::Language.to_3("ja").should eq "jpn"
      EasySubtitle::Language.to_3("fr").should eq "fre"
    end

    it "returns code as-is if unknown" do
      EasySubtitle::Language.to_3("xx").should eq "xx"
    end
  end

  describe ".equivalent?" do
    it "matches same codes" do
      EasySubtitle::Language.equivalent?("en", "en").should be_true
      EasySubtitle::Language.equivalent?("eng", "eng").should be_true
    end

    it "matches 2-letter and 3-letter equivalents" do
      EasySubtitle::Language.equivalent?("en", "eng").should be_true
      EasySubtitle::Language.equivalent?("eng", "en").should be_true
      EasySubtitle::Language.equivalent?("nl", "dut").should be_true
      EasySubtitle::Language.equivalent?("nld", "nl").should be_true
    end

    it "rejects different languages" do
      EasySubtitle::Language.equivalent?("en", "fr").should be_false
      EasySubtitle::Language.equivalent?("eng", "fre").should be_false
    end
  end
end
