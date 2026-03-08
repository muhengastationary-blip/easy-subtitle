module EasySubtitle
  module OffsetCalculator
    def self.calculate(original_path : Path, synced_path : Path) : Float64
      original_ts = first_timestamp(original_path)
      synced_ts = first_timestamp(synced_path)
      (original_ts - synced_ts).abs
    end

    def self.calculate(original_path : String, synced_path : String) : Float64
      calculate(Path.new(original_path), Path.new(synced_path))
    end

    def self.first_timestamp(path : Path) : Float64
      first_timestamp(path.to_s)
    end

    def self.first_timestamp(path : String) : Float64
      File.each_line(path) do |line|
        if line.includes?("-->")
          start_str = line.split("-->")[0].strip
          begin
            ts = Timestamp.parse(start_str)
            return ts.total_seconds
          rescue
            next
          end
        end
      end
      0.0
    end
  end
end
