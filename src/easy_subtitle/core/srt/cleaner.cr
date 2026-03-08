module EasySubtitle
  module SrtCleaner
    AD_PATTERNS = [
      /opensubtitles/i,
      /subscene/i,
      /addic7ed/i,
      /podnapisi/i,
      /subtitles?\s*(downloaded|by|from)/i,
      /downloaded\s*from/i,
      /www\.\w+\.\w+/i,
      /http[s]?:\/\//i,
      /support\s*us\s*and\s*become\s*vip/i,
      /become\s*(a\s*)?vip\s*member/i,
      /advertise\s*your\s*(product|brand)/i,
      /remove\s*all\s*ads/i,
      /captioning\s*sponsored/i,
      /synced?\s*(and\s*corrected|by)/i,
      /subtitle[sd]?\s*by/i,
      /encoded\s*by/i,
      /ripped\s*by/i,
      /fixed\s*by/i,
      /edited\s*by/i,
      /translation\s*by/i,
      /translated\s*by/i,
      /corrected\s*by/i,
      /resync(ed)?\s*by/i,
      /subs?\s*(made|created|ripped)/i,
      /please\s*rate\s*this\s*subtitle/i,
      /@\w+/,
      /follow\s*(us\s*)?(on\s*)?(twitter|facebook|instagram)/i,
      /telegram/i,
      /patreon\.com/i,
      /telesubtitles/i,
    ]

    def self.clean(blocks : Array(Block)) : Array(Block)
      cleaned = blocks.reject { |block| ad_block?(block) }
      SrtWriter.reindex(cleaned)
    end

    def self.clean_file(path : String, backup : Bool = true) : Int32
      clean_file(Path.new(path), backup)
    end

    def self.clean_file(path : Path, backup : Bool = true) : Int32
      blocks = SrtParser.parse_file(path)
      original_count = blocks.size

      cleaned = clean(blocks)
      removed = original_count - cleaned.size

      if removed > 0
        if backup
          backup_path = path.parent / "#{path.stem}.bak#{path.extension}"
          File.copy(path.to_s, backup_path.to_s)
        end
        SrtWriter.write_file(cleaned, path)
      end

      removed
    end

    def self.ad_block?(block : Block) : Bool
      text = block.content
      AD_PATTERNS.any? { |pattern| pattern.matches?(text) }
    end
  end
end
