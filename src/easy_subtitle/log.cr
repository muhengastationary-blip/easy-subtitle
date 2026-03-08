module EasySubtitle
  class Log
    enum Level
      Debug
      Info
      Warn
      Error
    end

    property level : Level = Level::Info
    property colorize : Bool = true
    property io : IO = STDERR

    def initialize(@level = Level::Info, @colorize = true, @io = STDERR)
    end

    def debug(msg : String)
      log(Level::Debug, msg, "\e[90m") # gray
    end

    def info(msg : String)
      log(Level::Info, msg, "\e[34m") # blue
    end

    def success(msg : String)
      log(Level::Info, msg, "\e[32m") # green
    end

    def warn(msg : String)
      log(Level::Warn, msg, "\e[33m") # yellow
    end

    def error(msg : String)
      log(Level::Error, msg, "\e[31m") # red
    end

    private def log(msg_level : Level, msg : String, color : String)
      return if msg_level < @level

      if @colorize
        @io.puts "#{color}#{msg}\e[0m"
      else
        @io.puts msg
      end
    end
  end
end
