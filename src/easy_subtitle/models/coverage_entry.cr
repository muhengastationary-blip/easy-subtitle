module EasySubtitle
  class CoverageEntry
    property video : VideoFile
    property subtitles : Hash(String, Array(Path))

    def initialize(@video, @subtitles = Hash(String, Array(Path)).new)
    end

    def has_language?(lang : String) : Bool
      normalized = Language.normalize(lang)
      subtitles.any? { |k, v| Language.normalize(k) == normalized && !v.empty? }
    end

    def languages_found : Array(String)
      subtitles.keys.select { |k| !subtitles[k].empty? }
    end

    def missing_languages(wanted : Array(String)) : Array(String)
      wanted.reject { |lang| has_language?(lang) }
    end

    def complete?(wanted : Array(String)) : Bool
      missing_languages(wanted).empty?
    end
  end
end
