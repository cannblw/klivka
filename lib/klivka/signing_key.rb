require "securerandom"
require "tempfile"

module Klivka
  module SigningKey
    MINIMUM_BYTES = 64

    class InvalidKey < StandardError; end

    module_function

    def validate!(value, source:)
      unless value.is_a?(String) && value.bytesize >= MINIMUM_BYTES && value == value.strip && !value.include?("\0")
        raise InvalidKey, "#{source} must contain at least #{MINIMUM_BYTES} bytes without surrounding whitespace"
      end

      value
    end
    private_class_method :validate!

    def ensure_file!(path)
      path = File.expand_path(path)
      directory = File.dirname(path)
      raise InvalidKey, "signing key directory does not exist: #{directory}" unless Dir.exist?(directory)

      lock_path = "#{path}.lock"
      File.open(lock_path, File::RDWR | File::CREAT, 0o600) do |lock|
        lock.flock(File::LOCK_EX)
        File.chmod(0o600, lock_path)

        if File.exist?(path)
          validate_file!(path)
        else
          create_file!(path, directory:)
        end
      end

      path
    rescue SystemCallError => error
      raise InvalidKey, "signing key could not be prepared: #{error.message}"
    end

    def validate_file!(path)
      stat = File.lstat(path)
      raise InvalidKey, "signing key path must be a regular file" unless stat.file?

      validate!(File.binread(path), source: "signing key file")
      File.chmod(0o600, path)
    end
    private_class_method :validate_file!

    def create_file!(path, directory:)
      temporary = Tempfile.new([ ".secret-key-base", ".tmp" ], directory, mode: 0o600)
      temporary.binmode
      temporary.write(SecureRandom.hex(MINIMUM_BYTES))
      temporary.flush
      temporary.fsync
      temporary.close
      File.rename(temporary.path, path)
      File.chmod(0o600, path)
    ensure
      temporary&.close!
    end
    private_class_method :create_file!
  end
end
