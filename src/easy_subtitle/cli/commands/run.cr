module EasySubtitle
  module CLI
    class RunCommand
      def initialize(@config : Config, @log : Log)
      end

      def run(args : Array(String)) : Nil
        skip_extract = false
        skip_download = false
        skip_sync = false

        parser = OptionParser.new do |p|
          p.banner = "Usage: easy-subtitle run [OPTIONS] PATH"
          p.on("--skip-extract", "Skip extraction phase") { skip_extract = true }
          p.on("--skip-download", "Skip download phase") { skip_download = true }
          p.on("--skip-sync", "Skip sync phase") { skip_sync = true }
        end
        parser.parse(args)

        path = args.last?
        unless path
          STDERR.puts parser
          return
        end

        # Track subtitles freshly extracted from video tracks so that
        # download/sync phases do not overwrite them — extracted subs are
        # already perfectly timed and should never be re-synced.
        extracted_finals = Set(String).new

        # Phase 1: Extract
        unless skip_extract
          pre_existing = collect_final_paths(path)

          @log.info "=== Phase 1: Extraction ==="
          ExtractCommand.new(@config, @log).run([path])

          post_existing = collect_final_paths(path)
          extracted_finals = post_existing - pre_existing

          unless extracted_finals.empty?
            @log.info "Extracted #{extracted_finals.size} subtitle(s) from video tracks — skipping download/sync for these"
          end
        end

        # Phase 2: Download
        unless skip_download
          @log.info "=== Phase 2: Download ==="
          DownloadCommand.new(@config, @log, extracted_finals: extracted_finals).run([path])
        end

        # Phase 3: Sync
        unless skip_sync
          @log.info "=== Phase 3: Synchronization ==="
          SyncCommand.new(@config, @log, extracted_finals: extracted_finals).run([path])
        end

        @log.success "=== Pipeline complete ==="
      end

      private def collect_final_paths(path : String) : Set(String)
        finals = Set(String).new
        videos = VideoScanner.scan(path, @config)
        videos.each do |video|
          @config.languages.each do |lang|
            final = SubtitleFiles.final_path(video, lang)
            finals << final.to_s if File.exists?(final.to_s)
          end
        end
        finals
      rescue
        Set(String).new
      end
    end
  end
end
