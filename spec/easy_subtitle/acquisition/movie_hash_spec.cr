require "../../spec_helper"

describe EasySubtitle::MovieHash do
  it "computes hash for a test file" do
    # Create a test file with known content
    path = "/tmp/easy-subtitle-hash-test.bin"
    File.open(path, "wb") do |f|
      # Write 128KB of data (first 64KB + last 64KB overlap for small files)
      (128 * 1024).times { |i| f.write_byte((i % 256).to_u8) }
    end

    hash = EasySubtitle::MovieHash.compute(path)
    hash.size.should eq 16
    hash.should match /^[0-9a-f]{16}$/
  ensure
    File.delete(path) if path && File.exists?(path)
  end

  it "produces consistent hashes" do
    path = "/tmp/easy-subtitle-hash-test2.bin"
    File.open(path, "wb") do |f|
      (128 * 1024).times { |i| f.write_byte((i % 256).to_u8) }
    end

    hash1 = EasySubtitle::MovieHash.compute(path)
    hash2 = EasySubtitle::MovieHash.compute(path)
    hash1.should eq hash2
  ensure
    File.delete(path) if path && File.exists?(path)
  end

  it "handles small files" do
    path = "/tmp/easy-subtitle-hash-test3.bin"
    File.write(path, "small content here")

    hash = EasySubtitle::MovieHash.compute(path)
    hash.size.should eq 16
    hash.should match /^[0-9a-f]{16}$/
  ensure
    File.delete(path) if path && File.exists?(path)
  end

  it "raises for non-existent file" do
    expect_raises(EasySubtitle::Error, /not found/) do
      EasySubtitle::MovieHash.compute("/tmp/nonexistent-movie-file.mkv")
    end
  end
end
