require "test_helper"

class FriendlyIdUnicodeSlugTest < ActiveSupport::TestCase
  CASES = [
    [ "Spanish accents and tilde ñ",  "Mabú Montáñez",   "mabu-montanez"    ],
    [ "Spanish standalone ñ",         "Peña García",     "pena-garcia"       ],
    [ "Polish nasal ą/ę and Ł",       "Łukasz Wąsik",    "lukasz-wasik"      ],
    [ "Polish ó and ź",               "Józef Błaszczyk", "jozef-blaszczyk"   ],
    [ "Czech háček ř/ž/í",            "Jiří Dvořák",     "jiri-dvorak"       ],
    [ "German umlauts ü/ö/ä",         "Jörg Müller",     "jorg-muller"       ],
    [ "French cédille and accent",    "François Côté",   "francois-cote"     ],
    [ "Nordic ø/å",                   "Søren Åberg",     "soren-aberg"       ],
    [ "Romanian ș/ț",                 "Ștefan Ionuț",    "stefan-ionut"      ],
    [ "Russian Cyrillic",             "Иван Петров",     "иван-петров"       ],
    [ "Chinese characters",           "张伟",             "张伟"               ],
    [ "Japanese kana and kanji",      "田中さくら",       "田中さくら"         ],
    [ "strips punctuation",           "O'Brien-Smith!",  "obrien-smith"      ],
    [ "collapses whitespace",         "  多い  空白  ",    "多い-空白"          ],
    [ "NFKC normalizes composites",   "Ame\u0301lie",    "amelie"            ]
  ]

  CASES.each do |description, input, expected|
    test "normalize: #{description}" do
      person = Person.new
      assert_equal expected, person.normalize_friendly_id(input)
    end
  end
end
