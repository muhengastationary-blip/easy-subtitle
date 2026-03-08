module EasySubtitle
  struct Timestamp
    include Comparable(Timestamp)

    getter total_ms : Int64

    PATTERN = /(\d{2}):(\d{2}):(\d{2}),(\d{3})/

    def initialize(@total_ms : Int64)
    end

    def initialize(hours : Int32, minutes : Int32, seconds : Int32, milliseconds : Int32)
      @total_ms = (hours.to_i64 * 3_600_000) +
                  (minutes.to_i64 * 60_000) +
                  (seconds.to_i64 * 1_000) +
                  milliseconds.to_i64
    end

    def self.parse(str : String) : Timestamp
      if match = PATTERN.match(str.strip)
        h = match[1].to_i
        m = match[2].to_i
        s = match[3].to_i
        ms = match[4].to_i
        Timestamp.new(h, m, s, ms)
      else
        raise SrtParseError.new("Invalid timestamp: #{str}")
      end
    end

    def hours : Int32
      (total_ms // 3_600_000).to_i32
    end

    def minutes : Int32
      ((total_ms % 3_600_000) // 60_000).to_i32
    end

    def seconds : Int32
      ((total_ms % 60_000) // 1_000).to_i32
    end

    def milliseconds : Int32
      (total_ms % 1_000).to_i32
    end

    def total_seconds : Float64
      total_ms / 1000.0
    end

    def +(other : Timestamp) : Timestamp
      Timestamp.new(total_ms + other.total_ms)
    end

    def -(other : Timestamp) : Timestamp
      Timestamp.new(total_ms - other.total_ms)
    end

    def <=>(other : Timestamp) : Int32
      total_ms <=> other.total_ms
    end

    def abs : Timestamp
      Timestamp.new(total_ms.abs)
    end

    def to_s(io : IO) : Nil
      io.printf "%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds
    end

    def to_s : String
      String.build { |io| to_s(io) }
    end
  end
end
