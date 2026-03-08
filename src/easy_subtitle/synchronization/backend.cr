module EasySubtitle
  abstract class SyncBackend
    DEFAULT_TIMEOUT = 10.minutes

    def initialize(@log : Log, @timeout : Time::Span = DEFAULT_TIMEOUT)
    end

    abstract def name : String
    abstract def binary_names : Array(String)
    abstract def install_help : String
    abstract def sync(video_path : Path, sub_in : Path, sub_out : Path) : ShellResult

    def available? : Bool
      !find_binary.nil?
    end

    protected def find_binary : String?
      binary_names.each do |binary_name|
        return binary_name if Shell.which(binary_name)
      end
      nil
    end

    protected def find_binary! : String
      find_binary || raise ExternalToolError.new(name, -1, "not found (tried: #{binary_names.join(", ")})")
    end
  end

  module SyncBackendFactory
    extend self

    def build(config : Config, log : Log) : SyncBackend
      build(config.sync_backend, log)
    end

    def build(name : String, log : Log) : SyncBackend
      case name.downcase
      when "alass"
        AlassRunner.new(log)
      when "ffsubsync"
        FfsubsyncRunner.new(log)
      else
        raise ConfigError.new("Unsupported sync_backend: #{name}")
      end
    end
  end
end
