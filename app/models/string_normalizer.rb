class StringNormalizer
  def self.call(value)
    value.to_s.unicode_normalize(:nfkc).squish
  end
end
