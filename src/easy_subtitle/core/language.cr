module EasySubtitle
  module Language
    LANG_3TO2 = {
      "eng" => "en", "dut" => "nl", "nld" => "nl", "ger" => "de", "deu" => "de",
      "fre" => "fr", "fra" => "fr", "spa" => "es", "ita" => "it", "por" => "pt",
      "rus" => "ru", "jpn" => "ja", "kor" => "ko", "chi" => "zh", "zho" => "zh",
      "swe" => "sv", "nor" => "no", "dan" => "da", "fin" => "fi", "pol" => "pl",
      "hun" => "hu", "cze" => "cs", "ces" => "cs", "slo" => "sk", "slk" => "sk",
      "slv" => "sl", "est" => "et", "lav" => "lv", "lat" => "lv", "lit" => "lt",
      "ell" => "el", "gre" => "el", "tur" => "tr", "ara" => "ar", "heb" => "he",
      "hin" => "hi", "tha" => "th", "vie" => "vi", "ind" => "id", "msa" => "ms",
      "may" => "ms", "tgl" => "tl", "fil" => "tl", "ukr" => "uk", "bul" => "bg",
      "hrv" => "hr", "scr" => "hr", "srp" => "sr", "ron" => "ro", "rum" => "ro",
      "cat" => "ca", "baq" => "eu", "eus" => "eu", "glg" => "gl", "isl" => "is",
      "ice" => "is", "mkd" => "mk", "mac" => "mk", "alb" => "sq", "sqi" => "sq",
      "bos" => "bs", "aze" => "az", "kaz" => "kk", "uzb" => "uz", "tat" => "tt",
      "kir" => "ky", "arm" => "hy", "hye" => "hy", "geo" => "ka", "kat" => "ka",
      "mya" => "my", "bur" => "my", "khm" => "km", "lao" => "lo", "nep" => "ne",
      "pan" => "pa", "sin" => "si", "tam" => "ta", "tel" => "te", "kan" => "kn",
      "mal" => "ml", "ori" => "or", "guj" => "gu", "ben" => "bn", "asm" => "as",
      "mar" => "mr", "san" => "sa", "urd" => "ur", "pes" => "fa", "fas" => "fa",
      "kur" => "ku", "pus" => "ps", "som" => "so", "amh" => "am", "tir" => "ti",
      "orm" => "om", "swa" => "sw", "kin" => "rw", "run" => "rn", "nya" => "ny",
      "zul" => "zu", "xho" => "xh", "afr" => "af", "ibo" => "ig", "yor" => "yo",
      "hau" => "ha", "sna" => "sn", "tsn" => "tn", "tso" => "ts", "ven" => "ve",
      "wol" => "wo", "fao" => "fo", "grn" => "gn", "aym" => "ay", "que" => "qu",
      "mlg" => "mg", "nav" => "nv", "gla" => "gd", "gle" => "ga", "cor" => "kw",
      "cym" => "cy", "wel" => "cy",
    }

    LANG_2TO3 = {
      "en" => "eng", "nl" => "dut", "de" => "ger", "fr" => "fre", "es" => "spa",
      "it" => "ita", "pt" => "por", "ru" => "rus", "ja" => "jpn", "ko" => "kor",
      "zh" => "zho", "sv" => "swe", "no" => "nor", "da" => "dan", "fi" => "fin",
      "pl" => "pol", "hu" => "hun", "cs" => "ces", "sk" => "slk", "sl" => "slv",
      "et" => "est", "lv" => "lav", "lt" => "lit", "el" => "ell", "tr" => "tur",
      "ar" => "ara", "he" => "heb", "hi" => "hin", "th" => "tha", "vi" => "vie",
      "id" => "ind", "ms" => "msa", "tl" => "tgl", "uk" => "ukr", "bg" => "bul",
      "hr" => "hrv", "sr" => "srp", "ro" => "ron", "ca" => "cat", "eu" => "eus",
      "gl" => "glg", "is" => "isl", "mk" => "mkd", "sq" => "alb", "bs" => "bos",
      "az" => "aze", "kk" => "kaz", "uz" => "uzb", "tt" => "tat", "ky" => "kir",
      "hy" => "arm", "ka" => "geo", "my" => "mya", "km" => "khm", "lo" => "lao",
      "ne" => "nep", "pa" => "pan", "si" => "sin", "ta" => "tam", "te" => "tel",
      "kn" => "kan", "ml" => "mal", "or" => "ori", "gu" => "guj", "bn" => "ben",
      "as" => "asm", "mr" => "mar", "sa" => "san", "ur" => "urd", "fa" => "fas",
      "ku" => "kur", "ps" => "pus", "so" => "som", "am" => "amh", "ti" => "tir",
      "om" => "orm", "sw" => "swa", "rw" => "kin", "rn" => "run", "ny" => "nya",
      "zu" => "zul", "xh" => "xho", "af" => "afr", "ig" => "ibo", "yo" => "yor",
      "ha" => "hau", "sn" => "sna", "tn" => "tsn", "ts" => "tso", "ve" => "ven",
      "wo" => "wol", "fo" => "fao", "gn" => "grn", "ay" => "aym", "qu" => "que",
      "mg" => "mlg", "nv" => "nav", "gd" => "gla", "ga" => "gle", "kw" => "cor",
      "cy" => "cym",
    }

    def self.to_2(code : String) : String
      code = code.downcase
      LANG_3TO2[code]? || code
    end

    def self.to_3(code : String) : String
      code = code.downcase
      LANG_2TO3[code]? || code
    end

    def self.equivalent?(lang1 : String, lang2 : String) : Bool
      normalize(lang1) == normalize(lang2)
    end

    def self.normalize(code : String) : String
      code = code.downcase
      if code.size == 3
        to_2(code)
      else
        code
      end
    end
  end
end
