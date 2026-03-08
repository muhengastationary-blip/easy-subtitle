module EasySubtitle
  class Syncer
    def initialize(@config : Config, @log : Log)
      @runner = AlassRunner.new(@log)
    end

    def sync(video : VideoFile, candidates : Array(Path), language : String) : SyncResult?
      if candidates.empty?
        @log.warn "No subtitle candidates to sync for #{video.name}"
        return nil
      end

      @log.info "Syncing #{candidates.size} candidate(s) for #{video.name} [#{language}]"

      result = if @config.smart_sync
                 SmartSync.new(@runner, @config, @log).execute(candidates, video)
               else
                 FirstMatch.new(@runner, @config, @log).execute(candidates, video)
               end

      if result && result.output_path
        finalize_result(result, video, language)
      end

      result
    end

    private def finalize_result(result : SyncResult, video : VideoFile, language : String) : Nil
      output = result.output_path
      return unless output

      final_name = "#{video.stem}.#{language}.srt"
      final_path = video.directory / final_name

      if result.accepted? || result.status.drift?
        begin
          File.rename(output.to_s, final_path.to_s)
          @log.success "Saved: #{final_name} (offset: #{result.offset.round(3)}s, status: #{result.status})"
        rescue ex
          @log.error "Failed to rename #{output.basename}: #{ex.message}"
        end
      end

      # Cleanup temp files for other candidates
      cleanup_temp_files(video.directory)
    end

    private def cleanup_temp_files(dir : Path) : Nil
      Dir.each_child(dir.to_s) do |name|
        if name.includes?("_synced.") || name.includes?("_synced_")
          path = dir / name
          File.delete(path.to_s) if File.file?(path.to_s)
        end
      end
    rescue
      # Ignore cleanup errors
    end
  end
end
