require "json"

module EasySubtitle
  class SubtitleDownloader
    struct DownloadAttempt
      getter success : Bool
      getter halt : Bool

      def initialize(@success : Bool, @halt : Bool = false)
      end

      def success? : Bool
        @success
      end

      def halt? : Bool
        @halt
      end
    end

    private struct DownloadLinkResult
      getter link : String?
      getter halt : Bool

      def initialize(@link : String? = nil, @halt : Bool = false)
      end
    end

    def initialize(@client : ApiClient, @config : Config, @log : Log)
    end

    def download(candidate : SubtitleCandidate, output_path : String) : DownloadAttempt
      download(candidate, Path.new(output_path))
    end

    def download(candidate : SubtitleCandidate, output_path : Path) : DownloadAttempt
      # Step 1: Request download link
      link_result = request_download_link(candidate.file_id)
      link = link_result.link
      return DownloadAttempt.new(false, halt: link_result.halt) unless link

      # Step 2: Download the actual subtitle file
      DownloadAttempt.new(download_file(link, output_path))
    end

    private def request_download_link(file_id : Int64) : DownloadLinkResult
      body = {"file_id" => file_id}.to_json

      retries = @config.download_retry_503
      retries.times do |attempt|
        response = @client.post("/download", body)

        case response.status_code
        when 200
          json = JSON.parse(response.body)
          link = json["link"]?.try(&.as_s?)
          unless link
            @log.error "Download response missing link for file #{file_id}"
            return DownloadLinkResult.new
          end
          return DownloadLinkResult.new(link: link)
        when 503
          wait = (attempt + 1) * 2
          @log.warn "503 Service Unavailable, retrying in #{wait}s (#{attempt + 1}/#{retries})"
          sleep(wait.seconds)
        else
          message = error_message(response.body)
          suffix = message ? ": #{message}" : ""
          @log.error "Download request failed for file #{file_id}: #{response.status_code}#{suffix}"
          return DownloadLinkResult.new(halt: halt_candidate_downloads?(response.status_code, message))
        end
      end

      @log.error "Download failed after #{retries} retries"
      DownloadLinkResult.new
    rescue ex : ApiError
      @log.error "Download request error: #{ex.message}"
      DownloadLinkResult.new
    rescue ex : JSON::ParseException
      @log.error "Download response was invalid JSON: #{ex.message}"
      DownloadLinkResult.new
    end

    private def download_file(url : String, output_path : Path) : Bool
      response = HTTP::Client.get(url)

      unless response.status_code == 200
        @log.error "Failed to download file: #{response.status_code}"
        return false
      end

      dir = output_path.parent
      Dir.mkdir_p(dir.to_s) unless Dir.exists?(dir.to_s)
      File.write(output_path, response.body)
      true
    rescue ex
      @log.error "Download error: #{ex.message}"
      false
    end

    private def halt_candidate_downloads?(status_code : Int32, message : String?) : Bool
      return true if {401, 403, 429}.includes?(status_code)
      return false unless status_code == 406 && message

      text = message.downcase
      {
        "quota",
        "limit",
        "remaining_downloads",
        "allowed_downloads",
        "daily",
        "vip",
      }.any? { |needle| text.includes?(needle) }
    end

    private def error_message(body : String) : String?
      text = body.strip
      return nil if text.empty?

      json = JSON.parse(text)

      message = json["message"]?.try(&.as_s?)
      details = json["errors"]?.try do |errors|
        next unless errors.as_a?
        errors.as_a.compact_map do |entry|
          entry.as_s? || entry["message"]?.try(&.as_s?)
        end.join(", ").presence
      end

      [message, details].compact.join(": ").presence || text
    rescue JSON::ParseException
      text
    end
  end
end
