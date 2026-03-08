module EasySubtitle
  class SubtitleCandidate
    property file_id : Int64
    property file_name : String
    property language : String
    property download_count : Int64
    property hearing_impaired : Bool
    property movie_hash_match : Bool
    property release : String
    property fps : Float64
    property from_trusted : Bool

    def initialize(
      @file_id,
      @file_name = "",
      @language = "en",
      @download_count = 0_i64,
      @hearing_impaired = false,
      @movie_hash_match = false,
      @release = "",
      @fps = 0.0,
      @from_trusted = false,
    )
    end

    def to_s(io : IO) : Nil
      io << "#{file_name} [#{language}] (downloads: #{download_count}"
      io << ", hash-match" if movie_hash_match
      io << ", HI" if hearing_impaired
      io << ")"
    end
  end
end
