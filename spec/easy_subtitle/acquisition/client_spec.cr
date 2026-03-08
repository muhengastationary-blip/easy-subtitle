require "../../spec_helper"
require "webmock"

describe EasySubtitle::ApiClient do
  before_each { WebMock.reset }
  after_each { WebMock.reset }

  it "sends authenticated GET requests" do
    config = EasySubtitle::Config.default
    config.api_key = "test_key"

    WebMock.stub(:post, "https://api.opensubtitles.com/api/v1/login")
      .to_return(body: %({"token": "jwt_token_123"}))

    WebMock.stub(:get, "https://api.opensubtitles.com/api/v1/subtitles?languages=en")
      .to_return(body: %({"data": []}))

    auth = EasySubtitle::Authenticator.new(config)
    client = EasySubtitle::ApiClient.new(config, auth)

    response = client.get("/subtitles", {"languages" => "en"})
    response.status_code.should eq 200
  end

  it "sends authenticated POST requests" do
    config = EasySubtitle::Config.default
    config.api_key = "test_key"

    WebMock.stub(:post, "https://api.opensubtitles.com/api/v1/login")
      .to_return(body: %({"token": "jwt_token_123"}))

    WebMock.stub(:post, "https://api.opensubtitles.com/api/v1/download")
      .to_return(body: %({"link": "https://example.com/sub.srt"}))

    auth = EasySubtitle::Authenticator.new(config)
    client = EasySubtitle::ApiClient.new(config, auth)

    response = client.post("/download", %({"file_id": 123}))
    response.status_code.should eq 200
  end
end
