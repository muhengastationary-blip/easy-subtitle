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

        # Phase 1: Extract
        unless skip_extract
          @log.info "=== Phase 1: Extraction ==="
          ExtractCommand.new(@config, @log).run([path])
        end

        # Collect all existing final subtitles. The run pipeline is
        # idempotent: it only downloads and syncs languages that are
        # still missing. resync_mode is ignored here — use the
        # standalone download/sync commands to force re-processing.
        existing_finals = collect_valid_finals(path)
        unless existing_finals.empty?
          @log.info "#{existing_finals.size} subtitle(s) already present — skipping download/sync for these"
        end

        # Phase 2: Download
        unless skip_download
          @log.info "=== Phase 2: Download ==="
          DownloadCommand.new(@config, @log, extracted_finals: existing_finals).run([path])
        end

        # Phase 3: Sync
        unless skip_sync
          @log.info "=== Phase 3: Synchronization ==="
          SyncCommand.new(@config, @log, extracted_finals: existing_finals).run([path])
        end

        @log.success "=== Pipeline complete ==="
      end

      private def collect_valid_finals(path : String) : Set(String)
        finals = Set(String).new
        videos = VideoScanner.scan(path, @config)
        videos.each do |video|
          @config.languages.each do |lang|
            final = SubtitleFiles.final_path(video, lang)
            final_str = final.to_s
            next unless File.exists?(final_str)
            next unless File.size(final_str) > 100
            finals << final_str
          end
        end
        finals
      rescue
        Set(String).new
      end
    end
  end
end
