require "../../spec_helper"

describe EasySubtitle::QueryBuilder do
  config = EasySubtitle::Config.default

  describe ".build" do
    it "cleans movie filename" do
      result = EasySubtitle::QueryBuilder.build("The.Matrix.1999.1080p.BluRay.x265.mkv", config)
      result.should eq "The Matrix 1999"
    end

    it "removes brackets and their content" do
      result = EasySubtitle::QueryBuilder.build("Movie [2024] (WEB-DL).mkv", config)
      result.strip.should_not contain "["
      result.strip.should_not contain "]"
    end

    it "handles series mode with SxxExx" do
      result = EasySubtitle::QueryBuilder.build("Breaking.Bad.S01E05.720p.BluRay.mkv", config, series_mode: true)
      result.should eq "Breaking Bad S01E05"
    end

    it "removes unwanted terms" do
      result = EasySubtitle::QueryBuilder.build("Movie.2024.HEVC.10bit.DTS.mkv", config)
      result.downcase.should_not contain "hevc"
      result.downcase.should_not contain "10bit"
      result.downcase.should_not contain "dts"
    end

    it "handles already clean names" do
      result = EasySubtitle::QueryBuilder.build("Inception.2010.mkv", config)
      result.should eq "Inception 2010"
    end

    it "removes file extension" do
      result = EasySubtitle::QueryBuilder.build("movie.mkv", config)
      result.should_not contain ".mkv"
    end
  end
end
