require "http/client"
require "json"

module EasySubtitle
  class Authenticator
    getter token : String?
    getter base_url : String?
    @token_path : Path

    def initialize(@config : Config)
      @token_path = Config.token_path
    end

    def ensure_token! : String
      if cached = load_cached_session
        @token = cached[:token]
        @base_url = cached[:base_url]
        return cached[:token]
      end

      login!
    end

    def login! : String
      body = {
        "username" => @config.username,
        "password" => @config.password,
      }.to_json

      headers = HTTP::Headers{
        "Content-Type" => "application/json",
        "Api-Key"      => @config.api_key,
        "User-Agent"   => "EasySubtitle v#{VERSION}",
      }

      response = HTTP::Client.post("#{@config.api_url}/login", headers: headers, body: body)

      unless response.status_code == 200
        raise ApiError.new(response.status_code, response.body)
      end

      json = JSON.parse(response.body)
      jwt = json["token"]?.try(&.as_s?) || raise ApiError.new(200, "Login response missing token")
      base_url = json["base_url"]?.try(&.as_s?) || @config.api_url

      save_session(jwt, base_url)
      @token = jwt
      @base_url = base_url
      jwt
    rescue ex : JSON::ParseException
      raise ApiError.new(200, "Invalid login response: #{ex.message}")
    rescue ex : IO::Error | Socket::Error
      raise ApiError.new(-1, "Login request failed: #{ex.message}")
    end

    def load_cached_session : NamedTuple(token: String, base_url: String)?
      return nil unless File.exists?(@token_path)
      content = File.read(@token_path).strip
      return nil if content.empty?

      return nil unless content.starts_with?('{')

      json = JSON.parse(content)
      token = json["token"]?.try(&.as_s?) || return nil
      base_url = json["base_url"]?.try(&.as_s?) || @config.api_url
      {token: token, base_url: base_url}
    rescue JSON::ParseException
      nil
    end

    def save_session(token : String, base_url : String) : Nil
      dir = @token_path.parent
      Dir.mkdir_p(dir.to_s) unless Dir.exists?(dir.to_s)
      File.write(@token_path, {"token" => token, "base_url" => base_url}.to_json)
    end

    def clear_token! : Nil
      File.delete(@token_path) if File.exists?(@token_path)
      @token = nil
      @base_url = nil
    end
  end
end
