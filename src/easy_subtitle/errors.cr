module EasySubtitle
  class Error < Exception
  end

  class ConfigError < Error
  end

  class ExternalToolError < Error
    getter tool : String
    getter exit_code : Int32
    getter stderr : String

    def initialize(@tool, @exit_code, @stderr = "")
      super("#{@tool} exited with code #{@exit_code}: #{@stderr}")
    end
  end

  class ApiError < Error
    getter status_code : Int32
    getter body : String

    def initialize(@status_code, @body = "")
      super("API error #{@status_code}: #{@body}")
    end
  end

  class SrtParseError < Error
  end
end
