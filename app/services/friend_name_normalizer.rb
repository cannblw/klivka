class FriendNameNormalizer
  def self.call(value)
    value.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").downcase.strip.gsub(/\s+/, " ")
  end
end
