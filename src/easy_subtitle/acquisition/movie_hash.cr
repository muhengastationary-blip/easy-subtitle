module EasySubtitle
  module MovieHash
    HASH_BLOCK_SIZE = 65536_i64 # 64KB

    def self.compute(path : Path) : String
      compute(path.to_s)
    end

    def self.compute(path : String) : String
      unless File.exists?(path)
        raise Error.new("Video file not found: #{path}")
      end

      file_size = File.info(path).size
      file_hash : UInt64 = file_size.to_u64

      File.open(path, "rb") do |f|
        # Hash first 64KB
        count = {HASH_BLOCK_SIZE, file_size}.min // 8
        count.times do
          chunk = read_uint64_le(f)
          break unless chunk
          file_hash = file_hash &+ chunk
        end

        # Hash last 64KB
        if file_size >= HASH_BLOCK_SIZE
          f.seek(file_size - HASH_BLOCK_SIZE)
        else
          f.seek(0)
        end

        count = {HASH_BLOCK_SIZE, file_size}.min // 8
        count.times do
          chunk = read_uint64_le(f)
          break unless chunk
          file_hash = file_hash &+ chunk
        end
      end

      "%016x" % file_hash
    end

    private def self.read_uint64_le(io : IO) : UInt64?
      bytes = Bytes.new(8)
      n = io.read(bytes)
      return nil if n < 8
      IO::ByteFormat::LittleEndian.decode(UInt64, bytes)
    end
  end
end
