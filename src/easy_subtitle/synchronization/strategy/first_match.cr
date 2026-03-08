module EasySubtitle
  class FirstMatch
    def initialize(@runner : AlassRunner, @config : Config, @log : Log)
    end

    def execute(candidates : Array(Path), video : VideoFile) : SyncResult?
      return nil if candidates.empty?

      best_drift : SyncResult? = nil

      candidates.each do |candidate|
        result = sync_one(candidate, video)

        if result.accepted?
          @log.success "First match accepted: #{candidate.basename} (timing shift: #{result.offset.round(3)}s)"
          return result
        end

        if result.status.drift?
          if best_drift.nil? || result.offset < best_drift.not_nil!.offset
            best_drift = result
          end
        end
      end

      if drift = best_drift
        @log.warn "No perfect match, best drift: #{drift.candidate_path.basename} (timing shift: #{drift.offset.round(3)}s)"
        return drift
      end

      @log.error "All #{candidates.size} candidates failed"
      nil
    end

    private def sync_one(candidate : Path, video : VideoFile) : SyncResult
      suffix = "_synced#{candidate.extension}"
      output_path = candidate.parent / "#{candidate.stem}#{suffix}"

      shell_result = @runner.sync(video.path, candidate, output_path)

      unless shell_result.exit_code == 0 && File.exists?(output_path)
        return SyncResult.new(
          candidate_path: candidate,
          status: SyncStatus::Failed,
          alass_output: shell_result.stderr,
        )
      end

      offset = measure_timing_shift(candidate, output_path)

      SyncResult.new(
        candidate_path: candidate,
        output_path: output_path,
        offset: offset,
        status: SyncStatus::Accepted,
        alass_output: shell_result.stdout,
      )
    rescue ex : Exception
      SyncResult.new(
        candidate_path: candidate,
        status: SyncStatus::Failed,
        alass_output: ex.message || "Synchronization failed",
      )
    end

    private def measure_timing_shift(candidate : Path, output_path : Path) : Float64
      OffsetCalculator.calculate(candidate, output_path)
    rescue
      0.0
    end
  end
end
