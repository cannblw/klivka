require "test_helper"

class VcardImport::ParserTest < ActiveSupport::TestCase
  test "maps supported repeated vCard properties from a version 4 card" do
    result = VcardImport::Parser.new(<<~VCARD).call
      BEGIN:VCARD
      VERSION:4.0
      FN:Zoë Example
      TEL;TYPE=cell,work;VALUE=uri:TEL:+44-20-1234
      TEL;TYPE=home:555-0100
      EMAIL;TYPE=work:ZOE@EXAMPLE.COM
      BDAY:1990-02-03
      ANNIVERSARY:2015-06-07
      NOTE:Line one\\nLine two
      END:VCARD
    VCARD

    assert_equal 0, result.rejected_count
    assert_equal [ {
      "id" => 0,
      "name" => "Zoë Example",
      "entries" => [
        { "type" => "Entry::Phone", "content" => { "number" => "+44-20-1234", "label" => "cell, work" } },
        { "type" => "Entry::Phone", "content" => { "number" => "555-0100", "label" => "home" } },
        { "type" => "Entry::Email", "content" => { "email" => "zoe@example.com", "label" => "work" } },
        { "type" => "Entry::Birthday", "entry_date" => "1990-02-03" },
        { "type" => "Entry::Date", "entry_date" => "2015-06-07", "content" => { "label" => "Anniversary" } },
        { "type" => "Entry::Note", "content" => { "text" => "Line one\nLine two" } }
      ]
    } ], result.candidates
  end

  test "uses the structured name when a version 2.1 card omits the formatted name" do
    result = VcardImport::Parser.new(<<~VCARD).call
      BEGIN:VCARD
      VERSION:2.1
      N:Lovelace;Ada;;;
      EMAIL;INTERNET:ada@example.com
      END:VCARD
    VCARD

    assert_equal "Ada Lovelace", result.candidates.first.fetch("name")
    assert_equal "ada@example.com", result.candidates.first.fetch("entries").first.dig("content", "email")
  end

  test "orders and unescapes every structured name part" do
    result = VcardImport::Parser.new(<<~VCARD).call
      BEGIN:VCARD
      VERSION:3.0
      N:Lovelace\\;Byron;Ada;Augusta;Dr.;III
      END:VCARD
    VCARD

    assert_equal "Dr. Ada Augusta Lovelace;Byron III", result.candidates.first.fetch("name")
  end

  test "retains valid cards when another card is malformed" do
    result = VcardImport::Parser.new(<<~VCARD).call
      BEGIN:VCARD
      VERSION:3.0
      FN:Ada Lovelace
      END:VCARD
      BEGIN:VCARD
      VERSION:3.0
      N:Broken;Card;;;
      EMAIL;TYPE=work
      END:VCARD
    VCARD

    assert_equal [ "Ada Lovelace" ], result.candidates.pluck("name")
    assert_equal 1, result.rejected_count
  end

  test "a card missing its end marker does not swallow the following valid card" do
    result = VcardImport::Parser.new(<<~VCARD).call
      BEGIN:VCARD
      VERSION:3.0
      FN:Broken Card
      BEGIN:VCARD
      VERSION:3.0
      FN:Grace Hopper
      END:VCARD
    VCARD

    assert_equal [ "Grace Hopper" ], result.candidates.pluck("name")
    assert_equal 1, result.rejected_count
  end

  test "accepts UTF-8 and UTF-16 sources with byte order marks" do
    source = <<~VCARD
      BEGIN:VCARD
      VERSION:3.0
      FN:Zoë Example
      END:VCARD
    VCARD
    encoded_sources = [
      "\xEF\xBB\xBF".b + source.b,
      "\xFF\xFE".b + source.encode(Encoding::UTF_16LE).b,
      "\xFE\xFF".b + source.encode(Encoding::UTF_16BE).b
    ]

    encoded_sources.each do |encoded_source|
      result = VcardImport::Parser.new(encoded_source).call

      assert_equal "Zoë Example", result.candidates.first.fetch("name")
    end
  end

  test "rejects a source whose bytes are not valid text" do
    assert_raises(VcardImport::Parser::InvalidEncodingError) do
      VcardImport::Parser.new("\xFFinvalid".b)
    end
  end

  test "does not map partial dates that Klivka cannot represent faithfully" do
    result = VcardImport::Parser.new(<<~VCARD).call
      BEGIN:VCARD
      VERSION:4.0
      FN:Ada Lovelace
      BDAY:--1210
      ANNIVERSARY:2015
      END:VCARD
    VCARD

    assert_empty result.candidates.first.fetch("entries")
  end

  test "enforces the configured card limit before parsing" do
    source = <<~VCARD
      BEGIN:VCARD
      VERSION:3.0
      FN:Ada Lovelace
      END:VCARD
      BEGIN:VCARD
      VERSION:3.0
      FN:Grace Hopper
      END:VCARD
    VCARD

    assert_raises(VcardImport::Parser::TooManyCardsError) do
      VcardImport::Parser.new(source, max_cards: 1).call
    end
  end

  test "omits blank phones, invalid emails, and blank notes" do
    result = VcardImport::Parser.new(<<~VCARD).call
      BEGIN:VCARD
      VERSION:3.0
      FN:Ada Lovelace
      TEL:
      EMAIL:not-an-email
      NOTE:
      END:VCARD
    VCARD

    assert_empty result.candidates.first.fetch("entries")
  end

  test "counts contact details that Klivka does not import" do
    result = VcardImport::Parser.new(<<~VCARD).call
      BEGIN:VCARD
      VERSION:4.0
      FN:Ada Lovelace
      ADR:1 Example Street
      X-SOCIALPROFILE:https://example.com/ada
      PHOTO;ENCODING=unknown:opaque-data
      UID:ada-lovelace
      END:VCARD
    VCARD

    assert_equal %w[ADR X-SOCIALPROFILE PHOTO], result.candidates.first.fetch("unsupported_properties")
  end
end
