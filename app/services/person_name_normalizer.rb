class PersonNameNormalizer
  def self.call(value)
    StringNormalizer.call(value).unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").downcase
  end
end
