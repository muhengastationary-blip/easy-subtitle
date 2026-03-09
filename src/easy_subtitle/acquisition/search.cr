require "json"

module EasySubtitle
  class SubtitleSearch
    def initialize(@client : ApiClient, @config : Config, @log : Log)
    end

    def search(video : VideoFile, language : String, series_mode : Bool = false) : Array(SubtitleCandidate)
      candidates = [] of SubtitleCandidate

      # Step 1: Hash search (most accurate)
      if @config.use_movie_hash && video.hash
        hash_results = search_by_hash(video.hash.not_nil!, language)
        if !hash_results.empty?
          @log.info "Found #{hash_results.size} hash-matched subtitle(s)"
          candidates.concat(hash_results)
        end
      end

      # Step 2: Text search (filtered by title to avoid wrong-show matches)
      query = QueryBuilder.build(video.name, @config, series_mode)
      unless query.empty?
        text_results = search_by_query(query, language)
        existing_ids = candidates.map(&.file_id).to_set
        text_results.each do |r|
          next if existing_ids.includes?(r.file_id)
          unless title_matches?(r.parent_title, video.stem)
            @log.debug "Filtered out wrong title: '#{r.parent_title}' (#{r.release})"
            next
          end
          candidates << r
        end
      end

      # Step 3: Last resort (unfiltered)
      if candidates.empty? && @config.last_resort_search
        @log.warn "No results, trying last resort search..."
        last_resort = search_last_resort(video.stem, language)
        candidates.concat(last_resort)
      end

      # Sort: hash matches first, then by download count
      candidates.sort_by! { |c| {c.movie_hash_match ? 0 : 1, -c.download_count} }
      candidates.first(@config.max_search_results)
    end

    private def search_by_hash(hash : String, language : String) : Array(SubtitleCandidate)
      params = {
        "moviehash" => hash,
        "languages" => language,
      }
      do_search(params, is_hash: true)
    end

    private def search_by_query(query : String, language : String) : Array(SubtitleCandidate)
      params = {
        "query"     => query,
        "languages" => language,
      }
      do_search(params)
    end

    private def search_last_resort(name : String, language : String) : Array(SubtitleCandidate)
      params = {
        "query"     => name,
        "languages" => language,
      }
      do_search(params)
    end

    private def do_search(params : Hash(String, String), is_hash : Bool = false) : Array(SubtitleCandidate)
      response = @client.get("/subtitles", params)

      unless response.status_code == 200
        @log.warn "Search returned #{response.status_code}"
        return [] of SubtitleCandidate
      end

      json = JSON.parse(response.body)
      data = json["data"]?.try(&.as_a?) || return [] of SubtitleCandidate

      results = [] of SubtitleCandidate
      data.each do |item|
        attrs = item["attributes"]?
        next unless attrs

        feature = attrs["feature_details"]?
        parent_title = feature.try(&.["parent_title"]?.try(&.as_s?)) ||
                       feature.try(&.["title"]?.try(&.as_s?)) || ""

        files = attrs["files"]?.try(&.as_a?) || next
        files.each do |file|
          file_id = file["file_id"]?.try(&.as_i64?) || next
          file_name = file["file_name"]?.try(&.as_s?) || ""

          results << SubtitleCandidate.new(
            file_id: file_id,
            file_name: file_name,
            language: attrs["language"]?.try(&.as_s?) || "",
            download_count: attrs["download_count"]?.try(&.as_i64?) || 0_i64,
            hearing_impaired: attrs["hearing_impaired"]?.try(&.as_bool?) || false,
            movie_hash_match: is_hash || (attrs["moviehash_match"]?.try(&.as_bool?) || false),
            release: attrs["release"]?.try(&.as_s?) || "",
            fps: attrs["fps"]?.try(&.as_f?) || 0.0,
            from_trusted: attrs["from_trusted"]?.try(&.as_bool?) || false,
            parent_title: parent_title,
          )
        end
      end

      results
    rescue ex : ApiError
      @log.error "Search failed: #{ex.message}"
      [] of SubtitleCandidate
    rescue ex : JSON::ParseException
      @log.error "Search returned invalid JSON: #{ex.message}"
      [] of SubtitleCandidate
    end

    # Verify that the subtitle's parent title matches the video filename.
    # All significant words (>1 char) from the title must appear in the
    # video stem, preventing e.g. "Modern Family" matching "SPY x FAMILY".
    private def title_matches?(parent_title : String, video_stem : String) : Bool
      return true if parent_title.empty?

      title_words = parent_title.downcase.split(/[^a-z0-9]+/).reject { |w| w.size < 2 }
      return true if title_words.empty?

      video_words = video_stem.downcase.split(/[^a-z0-9]+/).reject { |w| w.size < 2 }
      title_words.all? { |w| video_words.includes?(w) }
    end
  end
end
