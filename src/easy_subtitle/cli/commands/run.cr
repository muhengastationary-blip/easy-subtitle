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

        # Phase 2: Download
        unless skip_download
          @log.info "=== Phase 2: Download ==="
          DownloadCommand.new(@config, @log).run([path])
        end

        # Phase 3: Sync
        unless skip_sync
          @log.info "=== Phase 3: Synchronization ==="
          SyncCommand.new(@config, @log).run([path])
        end

        @log.success "=== Pipeline complete ==="
      end
    end
  end
end
