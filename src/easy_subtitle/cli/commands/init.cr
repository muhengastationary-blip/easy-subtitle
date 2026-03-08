module EasySubtitle
  module CLI
    class InitCommand
      def initialize(@log : Log)
      end

      def run(args : Array(String)) : Nil
        output_path = Config.default_path
        force = false

        OptionParser.parse(args) do |p|
          p.banner = "Usage: easy-subtitle init [OPTIONS]"
          p.on("-o PATH", "--output PATH", "Output path") { |path| output_path = Path.new(path) }
          p.on("-f", "--force", "Overwrite existing") { force = true }
        end

        if File.exists?(output_path) && !force
          @log.error "Config already exists: #{output_path}"
          @log.info "Use --force to overwrite"
          return
        end

        dir = output_path.parent
        Dir.mkdir_p(dir.to_s) unless Dir.exists?(dir.to_s)

        config = Config.default
        File.write(output_path, config.to_yaml_string)
        @log.success "Config written to: #{output_path}"
      end
    end
  end
end
