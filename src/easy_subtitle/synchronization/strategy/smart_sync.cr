module EasySubtitle
  class SmartSync
    def initialize(@runner : AlassRunner, @config : Config, @log : Log)
    end

    def execute(candidates : Array(Path), video : VideoFile) : SyncResult?
      return nil if candidates.empty?

      channel = Channel(SyncResult).new(candidates.size)

      candidates.each do |candidate|
        spawn do
          result = begin
            sync_one(candidate, video)
          rescue ex : Exception
            SyncResult.new(
              candidate_path: candidate,
              status: SyncStatus::Failed,
              alass_output: ex.message || "Synchronization failed",
            )
          end
          channel.send(result)
        end
      end

      results = Array(SyncResult).new(candidates.size)
      candidates.size.times do
        results << channel.receive
      end

      @log.info "Smart sync: #{results.count(&.accepted?)} accepted, #{results.count(&.status.drift?)} drift, #{results.count(&.status.failed?)} failed"

      accepted = results.select(&.accepted?)
      if accepted.empty?
        drift = results.select(&.status.drift?)
        return best_result(drift) if drift.any?
        return results.first?
      end

      best_result(accepted)
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

    private def best_result(results : Array(SyncResult)) : SyncResult
      results.max_by do |result|
        {
          candidate_download_count(result.candidate_path),
          -result.offset,
        }
      end
    end

    private def candidate_download_count(path : Path) : Int64
      if match = /\.d(\d+)\./.match(path.basename)
        match[1].to_i64
      else
        0_i64
      end
    end
  end
end
