require "digest/sha1"
require "file_utils"

module EasySubtitle
  module SubtitleCache
    extend self

    def root_path : Path
      Config.default_path.parent / "cache" / "subtitles"
    end

    def language_dir(video : VideoFile, language : String) : Path
      root_path / video_key(video) / language
    end

    def cached_candidate_file_ids(video : VideoFile, language : String) : Set(Int64)
      ids = Set(Int64).new
      begin
        dir = language_dir(video, language)
        return ids unless Dir.exists?(dir.to_s)

        Dir.each_child(dir.to_s) do |name|
          if file_id = SubtitleFiles.candidate_file_id(name)
            ids << file_id
          end
        end
      rescue
        # Ignore cache read errors
      end

      ids
    end

    def move_candidate(candidate : Path, video : VideoFile, language : String, status : SyncStatus) : Path
      target = language_dir(video, language) / SubtitleFiles.mark(candidate, status).basename

      dir = target.parent
      Dir.mkdir_p(dir.to_s) unless Dir.exists?(dir.to_s)

      if File.exists?(target.to_s)
        File.delete(candidate.to_s) if File.exists?(candidate.to_s)
      else
        begin
          File.rename(candidate.to_s, target.to_s)
        rescue ex : File::Error
          if ex.message.try(&.includes?("cross-device")) || ex.message.try(&.includes?("Invalid cross-device link"))
            File.copy(candidate.to_s, target.to_s)
            File.delete(candidate.to_s)
          else
            raise ex
          end
        end
      end

      target
    end

    def clear(video : VideoFile, language : String) : Nil
      dir = language_dir(video, language)
      return unless Dir.exists?(dir.to_s)

      FileUtils.rm_rf(dir.to_s)

      video_dir = dir.parent
      Dir.delete(video_dir.to_s) if Dir.exists?(video_dir.to_s) && Dir.children(video_dir.to_s).empty?
    rescue
      # Ignore cache cleanup errors
    end

    private def video_key(video : VideoFile) : String
      Digest::SHA1.hexdigest(video.path.to_s)
    end
  end
end
