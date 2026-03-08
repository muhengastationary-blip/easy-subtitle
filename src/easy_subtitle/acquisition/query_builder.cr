module EasySubtitle
  module QueryBuilder
    BRACKET_PATTERN      = /[\[\(\{].*?[\]\)\}]/
    SERIES_PATTERN       = /[Ss]\d{2}[Ee]\d{2}/
    YEAR_PATTERN         = /\b(19|20)\d{2}\b/
    SHORT_NUMBER_PATTERN = /\b\d{1,3}\b/

    def self.build(filename : String, config : Config, series_mode : Bool = false) : String
      name = Path.new(filename).stem
      name = strip_extension(name)
      name = clean_separators(name)
      name = remove_brackets(name)
      name = remove_unwanted_terms(name, config.unwanted_terms)

      if series_mode
        name = truncate_at_series_code(name)
      else
        name = truncate_at_year(name)
      end

      name = remove_short_numbers(name)
      name = collapse_whitespace(name)
      name.strip
    end

    private def self.strip_extension(name : String) : String
      name.gsub(/\.(mkv|mp4|avi|m4v|mov|wmv|srt|sub|ass)$/i, "")
    end

    private def self.clean_separators(name : String) : String
      name.gsub(/[._\-]/, " ")
    end

    private def self.remove_brackets(name : String) : String
      name.gsub(BRACKET_PATTERN, " ")
    end

    private def self.remove_unwanted_terms(name : String, terms : Array(String)) : String
      terms.each do |term|
        escaped = Regex.escape(term)
        name = name.gsub(/\b#{escaped}\b/i, " ")
      end
      name
    end

    private def self.truncate_at_series_code(name : String) : String
      if match = SERIES_PATTERN.match(name)
        name[0...match.end]
      else
        name
      end
    end

    private def self.truncate_at_year(name : String) : String
      if match = YEAR_PATTERN.match(name)
        name[0...match.end]
      else
        name
      end
    end

    private def self.remove_short_numbers(name : String) : String
      name.gsub(SHORT_NUMBER_PATTERN, " ")
    end

    private def self.collapse_whitespace(name : String) : String
      name.gsub(/\s+/, " ")
    end
  end
end
