require "../../spec_helper"

describe EasySubtitle::SyncBackendFactory do
  it "builds an alass runner" do
    backend = EasySubtitle::SyncBackendFactory.build("alass", EasySubtitle::Log.new(colorize: false, io: IO::Memory.new))
    backend.should be_a(EasySubtitle::AlassRunner)
  end

  it "builds an ffsubsync runner" do
    backend = EasySubtitle::SyncBackendFactory.build("ffsubsync", EasySubtitle::Log.new(colorize: false, io: IO::Memory.new))
    backend.should be_a(EasySubtitle::FfsubsyncRunner)
  end
end
