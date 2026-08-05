module FriendlyId
  # Transliterates Latin diacritics to ASCII (e.g. é→e, ñ→n, Ł→l)
  # while preserving non-Latin scripts (Cyrillic, CJK, Kana, etc.).
  #
  # Include after :slugged in the `use:` array so this override
  # takes precedence over FriendlyId::Slugged#normalize_friendly_id.
  module UnicodeSlug
    def normalize_friendly_id(value)
      value.to_s
        .unicode_normalize(:nfkc)
        .strip
        .downcase
        .chars
        .map! { |char| char.match?(/\p{Latin}/) ? transliterate_latin(char) : char }
        .join
        .gsub(/\s+/, "-")
        .gsub(/[^\p{L}\p{N}\-]/, "")
    end

    private

    def transliterate_latin(char)
      result = I18n.transliterate(char, replacement: nil)
      return result unless result.include?("?")

      # Fallback for characters missing from the transliteration table
      # (e.g. Romanian Ș/ș, Ț/ț): decompose and strip combining marks.
      char.unicode_normalize(:nfd).gsub(/\p{M}/, "")
    end
  end
end
