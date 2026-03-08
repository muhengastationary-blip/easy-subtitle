module EasySubtitle
  record ShellResult, stdout : String, stderr : String, exit_code : Int32

  module Shell
    def self.run(cmd : String, args : Array(String) = [] of String, raise_on_error : Bool = true) : ShellResult
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      status = Process.run(cmd, args, output: stdout, error: stderr)
      result = ShellResult.new(
        stdout: stdout.to_s,
        stderr: stderr.to_s,
        exit_code: status.exit_code
      )

      if raise_on_error && !status.success?
        raise ExternalToolError.new(cmd, result.exit_code, result.stderr.strip)
      end

      result
    end

    def self.run(cmd : String, args : Array(String), raise_on_error : Bool = true, timeout : Time::Span? = nil) : ShellResult
      if timeout.nil?
        return run(cmd, args, raise_on_error)
      end

      stdout = IO::Memory.new
      stderr = IO::Memory.new

      process = Process.new(cmd, args, output: stdout, error: stderr)

      channel = Channel(Process::Status).new(1)
      spawn { channel.send(process.wait) }

      select
      when status = channel.receive
        result = ShellResult.new(
          stdout: stdout.to_s,
          stderr: stderr.to_s,
          exit_code: status.exit_code
        )

        if raise_on_error && !status.success?
          raise ExternalToolError.new(cmd, result.exit_code, result.stderr.strip)
        end

        result
      when timeout(timeout.not_nil!)
        process.terminate
        raise ExternalToolError.new(cmd, -1, "Process timed out after #{timeout}")
      end
    end

    def self.which(cmd : String) : String?
      result = run("which", [cmd], raise_on_error: false)
      result.exit_code == 0 ? result.stdout.strip : nil
    end
  end
end
