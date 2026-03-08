module EasySubtitle
  class VideoFile
    getter path : Path
    getter size : Int64
    property hash : String?

    def initialize(@path, @size, @hash = nil)
    end

    def self.from_path(path : Path) : VideoFile
      info = File.info(path)
      VideoFile.new(path: path, size: info.size)
    end

    def self.from_path(path : String) : VideoFile
      from_path(Path.new(path))
    end

    def name : String
      path.basename
    end

    def stem : String
      path.stem
    end

    def directory : Path
      path.parent
    end

    def extension : String
      path.extension
    end

    def compute_hash! : String
      h = MovieHash.compute(path)
      @hash = h
      h
    end
  end
end
