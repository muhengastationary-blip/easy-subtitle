module EasySubtitle
  module CLI
    class HashCommand
      def initialize(@log : Log)
      end

      def run(args : Array(String)) : Nil
        verbose = false

        parser = OptionParser.new do |p|
          p.banner = "Usage: easy-subtitle hash [OPTIONS] FILE"
          p.on("-v", "--verbose", "Show detailed info") { verbose = true }
        end
        parser.parse(args)

        path = args.last?
        unless path
          STDERR.puts parser
          return
        end

        unless File.exists?(path)
          @log.error "File not found: #{path}"
          return
        end

        hash = MovieHash.compute(path)
        file_size = File.info(path).size

        if verbose
          puts "File: #{path}"
          puts "Size: #{file_size.format} bytes (#{(file_size / (1024 * 1024)).round(2)} MB)"
          puts "Hash: #{hash}"
        else
          puts hash
        end
      end
    end
  end
end
