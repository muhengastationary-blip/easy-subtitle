require "../../spec_helper"

describe EasySubtitle::SmartSync do
  # SmartSync requires alass and real files to test properly.
  # These specs test the classification logic via SyncResult.

  describe "SyncResult" do
    it "reports accepted status" do
      result = EasySubtitle::SyncResult.new(
        candidate_path: Path.new("/tmp/test.srt"),
        offset: 0.05,
        status: EasySubtitle::SyncStatus::Accepted,
      )
      result.accepted?.should be_true
    end

    it "reports drift status" do
      result = EasySubtitle::SyncResult.new(
        candidate_path: Path.new("/tmp/test.srt"),
        offset: 1.5,
        status: EasySubtitle::SyncStatus::Drift,
      )
      result.accepted?.should be_false
      result.status.drift?.should be_true
    end

    it "reports failed status" do
      result = EasySubtitle::SyncResult.new(
        candidate_path: Path.new("/tmp/test.srt"),
        status: EasySubtitle::SyncStatus::Failed,
      )
      result.accepted?.should be_false
      result.status.failed?.should be_true
    end
  end
end
