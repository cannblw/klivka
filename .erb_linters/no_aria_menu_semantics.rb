require "better_html/tree/tag"

module ERBLint
  module Linters
    class NoAriaMenuSemantics < Linter
      include LinterRegistry

      MENU_ROLES = %w[menu menuitem menuitemcheckbox menuitemradio].freeze

      def run(processed_source)
        processed_source.parser.nodes_with_type(:tag).each do |tag_node|
          tag = BetterHtml::Tree::Tag.from_node(tag_node)

          check_role(tag.attributes["role"])
          check_haspopup(tag.attributes["aria-haspopup"])
        end
      end

      private

      def check_role(attribute)
        return unless attribute&.value.to_s.downcase.split.intersect?(MENU_ROLES)

        add_offense(attribute.loc, "ARIA menu roles require an explicit lint exemption and complete keyboard behavior.")
      end

      def check_haspopup(attribute)
        return unless attribute&.value.to_s.casecmp?("menu")

        add_offense(attribute.loc, "aria-haspopup=\"menu\" requires an explicit lint exemption and complete keyboard behavior.")
      end
    end
  end
end
