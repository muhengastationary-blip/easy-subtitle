require "spec"
require "file_utils"
require "../src/easy_subtitle"

FIXTURES_PATH = Path[__DIR__] / "fixtures"

def fixture(name : String) : String
  (FIXTURES_PATH / name).to_s
end

def read_fixture(name : String) : String
  File.read(fixture(name))
end
