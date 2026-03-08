module EasySubtitle
  class FfsubsyncRunner < SyncBackend
    BINARY_NAMES = ["ffsubsync"]

    def name : String
      "ffsubsync"
    end

    def binary_names : Array(String)
      BINARY_NAMES
    end

    def install_help : String
      "pipx install ffsubsync  OR  pip install ffsubsync"
    end

    def sync(video_path : Path, sub_in : Path, sub_out : Path) : ShellResult
      cmd = find_binary!
      @log.debug "Running #{cmd}: #{video_path.basename} + #{sub_in.basename}"
      Spinner.run("Syncing #{sub_in.basename}") do
        Shell.run(
          cmd,
          [video_path.to_s, "-i", sub_in.to_s, "-o", sub_out.to_s],
          raise_on_error: false,
          timeout: @timeout
        )
      end
    end
  end
end
