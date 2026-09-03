require "test_helper"
require "klivka/signing_key"

class Klivka::SigningKeyTest < ActiveSupport::TestCase
  test "creates a strong private signing key and reuses it" do
    Dir.mktmpdir do |directory|
      path = File.join(directory, ".secret_key_base")

      Klivka::SigningKey.ensure_file!(path)
      original = File.binread(path)
      Klivka::SigningKey.ensure_file!(path)

      assert_equal 128, original.bytesize
      assert_equal original, File.binread(path)
      assert_equal 0o600, File.stat(path).mode & 0o777
    end
  end

  test "serializes concurrent signing key creation" do
    Dir.mktmpdir do |directory|
      path = File.join(directory, ".secret_key_base")

      threads = 8.times.map do
        Thread.new { Klivka::SigningKey.ensure_file!(path) }
      end
      threads.each(&:value)

      assert_equal 128, File.binread(path).bytesize
      assert_equal 0o600, File.stat(path).mode & 0o777
    end
  end

  test "rejects an empty or weak existing signing key" do
    Dir.mktmpdir do |directory|
      path = File.join(directory, ".secret_key_base")
      File.write(path, "too-short")

      error = assert_raises(Klivka::SigningKey::InvalidKey) do
        Klivka::SigningKey.ensure_file!(path)
      end

      assert_match(/at least 64 bytes/, error.message)
      assert_equal "too-short", File.read(path)
    end
  end

  test "rejects a signing key symlink" do
    Dir.mktmpdir do |directory|
      target = File.join(directory, "target")
      path = File.join(directory, ".secret_key_base")
      File.write(target, "a" * 64)
      File.symlink(target, path)

      error = assert_raises(Klivka::SigningKey::InvalidKey) do
        Klivka::SigningKey.ensure_file!(path)
      end

      assert_match(/regular file/, error.message)
    end
  end
end
