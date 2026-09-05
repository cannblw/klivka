require "test_helper"
require "erb_lint/all"
require Rails.root.join(".erb_linters/no_aria_menu_semantics").to_s

class NoAriaMenuSemanticsTest < ActiveSupport::TestCase
  test "the ARIA menu linter rejects menu roles" do
    %w[menu menuitem menuitemcheckbox menuitemradio].each do |role|
      offenses = offenses_for(%(<div role="#{role}"></div>))

      assert_equal 1, offenses.size, "Expected role=#{role.inspect} to be rejected"
    end
  end

  test "the ARIA menu linter rejects menu popup semantics" do
    offenses = offenses_for('<button aria-haspopup="menu">Actions</button>')

    assert_equal 1, offenses.size
  end

  test "the ARIA menu linter accepts unrelated ARIA semantics" do
    source = <<~ERB
      <nav aria-label="Primary"></nav>
      <button aria-haspopup="dialog">Open</button>
      <div role="group"></div>
    ERB

    assert_empty offenses_for(source)
  end

  test "the ARIA menu linter treats role tokens and attribute values case-insensitively" do
    source = <<~ERB
      <div role="navigation MENU"></div>
      <button aria-haspopup="MENU">Actions</button>
    ERB

    assert_equal 2, offenses_for(source).size
  end

  private

  def offenses_for(source)
    linter = ERBLint::Linters::NoAriaMenuSemantics.new(
      ERBLint::FileLoader.new(Rails.root),
      ERBLint::LinterConfig.new(enabled: true)
    )
    linter.run(ERBLint::ProcessedSource.new("example.html.erb", source.dup))
    linter.offenses
  end
end
