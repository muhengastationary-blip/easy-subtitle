module EasySubtitle
  struct Block
    property index : Int32
    property start_time : Timestamp
    property end_time : Timestamp
    property lines : Array(String)

    def initialize(@index, @start_time, @end_time, @lines)
    end

    def content : String
      lines.join("\n")
    end

    def to_s(io : IO) : Nil
      io.puts index
      io << start_time << " --> " << end_time
      io.puts
      lines.each { |line| io.puts line }
    end

    def to_s : String
      String.build { |io| to_s(io) }
    end
  end
end
