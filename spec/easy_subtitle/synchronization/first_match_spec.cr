require "../../spec_helper"

describe EasySubtitle::FirstMatch do
  # FirstMatch requires alass and real files to test properly.
  # Test the SyncStatus enum behavior.

  describe "SyncStatus" do
    it "has expected values" do
      EasySubtitle::SyncStatus::Accepted.accepted?.should be_true
      EasySubtitle::SyncStatus::Drift.drift?.should be_true
      EasySubtitle::SyncStatus::Failed.failed?.should be_true
    end
  end
end
