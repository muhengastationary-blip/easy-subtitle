require "../../spec_helper"

describe EasySubtitle::SubtitleFiles do
  it "distinguishes final, active, and marked subtitle files" do
    video = EasySubtitle::VideoFile.new(path: Path.new("/tmp/movie.mkv"), size: 0_i64)

    EasySubtitle::SubtitleFiles.final_subtitle?("movie.en.srt", video, "en").should be_true
    EasySubtitle::SubtitleFiles.active_candidate?("movie.en.d100.f1.srt", video, "en").should be_true
    EasySubtitle::SubtitleFiles.active_candidate?("movie.en.srt", video, "en").should be_false
    EasySubtitle::SubtitleFiles.active_candidate?("movie.en.d100.f1.DRIFT.srt", video, "en").should be_false
    EasySubtitle::SubtitleFiles.active_candidate?("movie.en.d100.f1.FAILED.srt", video, "en").should be_false
  end

  it "extracts candidate metadata from filenames" do
    EasySubtitle::SubtitleFiles.candidate_download_count("movie.en.d123.f456.srt").should eq 123_i64
    EasySubtitle::SubtitleFiles.candidate_file_id("movie.en.d123.f456.srt").should eq 456_i64
    EasySubtitle::SubtitleFiles.candidate_file_id("movie.en.d123.f456.FAILED.srt").should eq 456_i64
  end

  it "builds marker filenames" do
    path = Path.new("/tmp/movie.en.d123.f456.srt")

    EasySubtitle::SubtitleFiles.mark(path, EasySubtitle::SyncStatus::Drift).basename.should eq "movie.en.d123.f456.DRIFT.srt"
    EasySubtitle::SubtitleFiles.mark(path, EasySubtitle::SyncStatus::Failed).basename.should eq "movie.en.d123.f456.FAILED.srt"
  end
end

describe EasySubtitle::SubtitleCache do
  it "moves failed candidates into the centralized cache" do
    dir = Path.new("/tmp/easy-subtitle-cache-spec")
    Dir.mkdir_p(dir.to_s)

    video_path = dir / "movie.mkv"
    candidate = dir / "movie.en.d123.f456.srt"

    File.write(video_path.to_s, "video")
    File.write(candidate.to_s, "1\n00:00:01,000 --> 00:00:02,000\nhi\n")

    video = EasySubtitle::VideoFile.from_path(video_path)
    cached = EasySubtitle::SubtitleCache.move_candidate(candidate, video, "en", EasySubtitle::SyncStatus::Failed)

    File.exists?(candidate.to_s).should be_false
    cached.basename.should eq "movie.en.d123.f456.FAILED.srt"
    File.exists?(cached.to_s).should be_true
    EasySubtitle::SubtitleCache.cached_candidate_file_ids(video, "en").should contain 456_i64
  ensure
    EasySubtitle::SubtitleCache.clear(video, "en") if video
    FileUtils.rm_rf(dir.to_s) if dir
  end
end
