module EasySubtitle
  module CLI
    class DoctorCommand
      def initialize(@config : Config, @log : Log)
        @config_path = Config.default_path.to_s
        @passed = 0
        @total = 0
      end

      def run(args : Array(String)) : Nil
        OptionParser.parse(args) do |p|
          p.banner = "Usage: easy-subtitle doctor"
          p.on("-c PATH", "--config PATH", "Config file path") { |path| @config_path = path }
        end

        puts "Checking easy-subtitle setup...\n"

        check_config_file
        load_real_config
        check_api_key
        check_credentials
        check_api_login
        check_tool("mkvmerge", mkvtoolnix_install_help)
        check_tool("mkvextract", mkvtoolnix_install_help)
        check_sync_backend

        if @config.sync_backend.downcase == "whisper"
          check_tool("ffmpeg", ffmpeg_install_help)
          check_alass_for_whisper
          check_whisper_model
        end

        puts "\n#{@passed}/#{@total} checks passed"
      end

      private def check_config_file
        if File.exists?(@config_path)
          pass("Config file exists: #{@config_path}")
        else
          fail("Config file not found: #{@config_path}")
          @log.info "  Run: easy-subtitle init"
        end
      end

      private def load_real_config
        return unless File.exists?(@config_path)
        @config = Config.load(@config_path)
      rescue ex : ConfigError
        @log.warn "Config load error: #{ex.message}"
      end

      private def check_api_key
        if !@config.api_key.empty?
          pass("API key is set")
        else
          fail("API key is empty")
        end
      end

      private def check_credentials
        missing = [] of String
        missing << "username" if @config.username.empty?
        missing << "password" if @config.password.empty?

        if missing.empty?
          pass("Username and password are set")
        else
          fail("Missing credentials: #{missing.join(", ")}")
        end
      end

      private def check_api_login
        if @config.api_key.empty? || @config.username.empty? || @config.password.empty?
          skip("API login (skipped — credentials incomplete)")
          return
        end

        begin
          Authenticator.new(@config).login!
          pass("API login successful")
        rescue ex : ApiError
          fail("API login failed (HTTP #{ex.status_code}): #{ex.body}")
        rescue ex : Exception
          fail("API login failed: #{ex.message}")
        end
      end

      private def check_tool(name : String, install_help : String)
        if path = Shell.which(name)
          pass("#{name} found: #{path}")
        else
          fail("#{name} not found")
          @log.info "  Install: #{install_help}"
        end
      end

      private def check_sync_backend
        backend = SyncBackendFactory.build(@config, @log)
        backend.binary_names.each do |binary_name|
          if path = Shell.which(binary_name)
            pass("#{backend.name} backend found: #{path}")
            return
          end
        end

        fail("#{backend.name} backend not found (tried: #{backend.binary_names.join(", ")})")
        @log.info "  Install: #{backend.install_help}"
      end

      private def detect_platform : String
        result = Shell.run("uname", ["-s"], raise_on_error: false)
        result.exit_code == 0 ? result.stdout.strip : "Unknown"
      end

      private def check_alass_for_whisper
        WhisperRunner::ALASS_BINARY_NAMES.each do |name|
          if path = Shell.which(name)
            pass("alass (for whisper alignment) found: #{path}")
            return
          end
        end
        fail("alass not found (required by whisper backend)")
        @log.info "  Install: cargo install alass-cli"
      end

      private def check_whisper_model
        model_name = @config.whisper_model
        if model_name == "auto"
          all_english = @config.audio_track_languages.all? { |l| Language.normalize(l) == "en" }
          model_name = all_english ? "base.en" : "small"
        end

        filename = WhisperRunner::MODELS[model_name]?
        unless filename
          fail("Unknown whisper_model: '#{@config.whisper_model}'")
          return
        end

        model_path = WhisperRunner::MODEL_DIR / filename
        if File.exists?(model_path.to_s)
          pass("Whisper model '#{model_name}': #{model_path}")
        else
          skip("Whisper model '#{model_name}' not downloaded yet (will download on first sync)")
        end
      end

      private def ffmpeg_install_help : String
        case detect_platform
        when "Linux"
          "sudo apt install ffmpeg  OR  sudo pacman -S ffmpeg"
        when "Darwin"
          "brew install ffmpeg"
        else
          "https://ffmpeg.org/download.html"
        end
      end

      private def mkvtoolnix_install_help : String
        case detect_platform
        when "Linux"
          "sudo apt install mkvtoolnix  OR  sudo pacman -S mkvtoolnix-cli"
        when "Darwin"
          "brew install mkvtoolnix"
        else
          "https://mkvtoolnix.download/downloads.html"
        end
      end

      private def pass(msg : String)
        @total += 1
        @passed += 1
        puts "\e[32m✓\e[0m #{msg}"
      end

      private def fail(msg : String)
        @total += 1
        puts "\e[31m✗\e[0m #{msg}"
      end

      private def skip(msg : String)
        @total += 1
        puts "\e[33m–\e[0m #{msg}"
      end
    end
  end
end
