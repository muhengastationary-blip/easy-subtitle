module EasySubtitle
  struct SubtitleTrack
    property id : Int32
    property language : String
    property codec : String
    property codec_id : String
    property name : String
    property default : Bool
    property forced : Bool

    def initialize(@id, @language, @codec, @codec_id = "", @name = "", @default = false, @forced = false)
    end

    def srt_compatible? : Bool
      codec_id = @codec_id.downcase
      codec_id.includes?("utf8") ||
        codec_id.includes?("srt") ||
        codec_id.includes?("subrip") ||
        codec_id.includes?("s_text/utf8") ||
        codec_id.includes?("s_text/ascii")
    end

    def ass? : Bool
      codec_id = @codec_id.downcase
      codec_id.includes?("ass") || codec_id.includes?("ssa")
    end

    def extractable? : Bool
      srt_compatible? || ass?
    end

    def language_2 : String
      Language.to_2(language)
    end
  end

  struct AudioTrack
    property id : Int32
    property language : String
    property codec : String
    property name : String
    property default : Bool

    def initialize(@id, @language, @codec, @name = "", @default = false)
    end

    def language_2 : String
      Language.to_2(language)
    end
  end
end
