module EasySubtitle
  module SrtParser
    def self.parse(content : String) : Array(Block)
      blocks = [] of Block
      # Remove BOM if present
      content = content.lstrip('\uFEFF')
      raw_blocks = content.strip.split(/\n\s*\n/)

      raw_blocks.each do |raw|
        raw = raw.strip
        next if raw.empty?

        block_lines = raw.split('\n')
        next if block_lines.size < 2

        # First line: index
        index_str = block_lines[0].strip
        index = index_str.to_i? || next

        # Second line: timestamps
        time_line = block_lines[1].strip
        unless time_line.includes?("-->")
          next
        end

        parts = time_line.split("-->").map(&.strip)
        next if parts.size != 2

        begin
          start_time = Timestamp.parse(parts[0])
          end_time = Timestamp.parse(parts[1])
        rescue
          next
        end

        # Remaining lines: content
        content_lines = block_lines[2..].map(&.rstrip)
        # Remove trailing empty lines
        while content_lines.last?.try(&.empty?)
          content_lines.pop
        end

        blocks << Block.new(
          index: index,
          start_time: start_time,
          end_time: end_time,
          lines: content_lines
        )
      end

      blocks
    end

    def self.parse_file(path : String) : Array(Block)
      content = File.read(path)
      parse(content)
    end

    def self.parse_file(path : Path) : Array(Block)
      parse_file(path.to_s)
    end
  end
end
