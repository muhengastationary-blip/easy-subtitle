module EasySubtitle
  module SrtWriter
    def self.write(blocks : Array(Block), io : IO) : Nil
      blocks.each_with_index do |block, i|
        io.puts block.index
        io << block.start_time << " --> " << block.end_time
        io.puts
        block.lines.each { |line| io.puts line }
        io.puts if i < blocks.size - 1
      end
    end

    def self.to_s(blocks : Array(Block)) : String
      String.build { |io| write(blocks, io) }
    end

    def self.write_file(blocks : Array(Block), path : String) : Nil
      File.write(path, to_s(blocks))
    end

    def self.write_file(blocks : Array(Block), path : Path) : Nil
      write_file(blocks, path.to_s)
    end

    def self.reindex(blocks : Array(Block)) : Array(Block)
      blocks.map_with_index do |block, i|
        Block.new(
          index: i + 1,
          start_time: block.start_time,
          end_time: block.end_time,
          lines: block.lines
        )
      end
    end
  end
end
