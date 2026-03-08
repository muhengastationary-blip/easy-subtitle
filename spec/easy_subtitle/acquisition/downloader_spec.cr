require "../../spec_helper"
require "http/client"

private class StubApiClient < EasySubtitle::ApiClient
  def initialize(@responses : Array(HTTP::Client::Response))
    super(EasySubtitle::Config.default, EasySubtitle::Authenticator.new(EasySubtitle::Config.default))
  end

  def post(path : String, body : String? = nil) : HTTP::Client::Response
    @responses.shift? || raise "no more responses configured"
  end
end

describe EasySubtitle::SubtitleDownloader do
  it "logs the API message for 406 responses" do
    io = IO::Memory.new
    log = EasySubtitle::Log.new(colorize: false, io: io)
    client = StubApiClient.new([
      HTTP::Client::Response.new(406, body: %({"message":"Invalid file_id"})),
    ])

    downloader = EasySubtitle::SubtitleDownloader.new(client, EasySubtitle::Config.default, log)
    candidate = EasySubtitle::SubtitleCandidate.new(file_id: 123_i64)

    result = downloader.download(candidate, Path.new("/tmp/unused.srt"))
    result.success?.should be_false
    result.halt?.should be_false
    io.to_s.should contain("Download request failed for file 123: 406: Invalid file_id")
  end

  it "halts further attempts when 406 indicates a quota limit" do
    io = IO::Memory.new
    log = EasySubtitle::Log.new(colorize: false, io: io)
    client = StubApiClient.new([
      HTTP::Client::Response.new(406, body: %({"message":"daily download quota exceeded"})),
    ])

    downloader = EasySubtitle::SubtitleDownloader.new(client, EasySubtitle::Config.default, log)
    candidate = EasySubtitle::SubtitleCandidate.new(file_id: 456_i64)

    result = downloader.download(candidate, Path.new("/tmp/unused.srt"))
    result.success?.should be_false
    result.halt?.should be_true
  end
end
