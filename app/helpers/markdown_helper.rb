# frozen_string_literal: true

module MarkdownHelper
  EXTENSIONS = { table: true, strikethrough: true, autolink: true }.freeze

  # allowed_tags / allowed_attributes are Sets, so convert before appending.
  # Table tags are not allowed by default, and id is needed to keep the
  # heading anchors commonmarker generates.
  ALLOWED_TAGS = (Rails::HTML5::SafeListSanitizer.allowed_tags.to_a +
    %w[table thead tbody tfoot tr th td]).freeze
  ALLOWED_ATTRIBUTES = (Rails::HTML5::SafeListSanitizer.allowed_attributes.to_a + %w[id]).freeze

  LINK_REL = "nofollow noopener"

  # Takes a Summary rather than a string because the cache key needs the record version.
  def render_markdown(summary)
    Rails.cache.fetch([ "markdown", summary.cache_key_with_version ]) do
      html = Commonmarker.to_html(
        summary.body.to_s,
        options: { extension: EXTENSIONS, render: { unsafe: false } }
      )
      add_link_rel(sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES))
    end
  end

  private

  # sanitize is the safety boundary; this only adds attributes to already
  # sanitized HTML, so marking it html_safe again is fine.
  def add_link_rel(html)
    fragment = Nokogiri::HTML5.fragment(html)
    fragment.css("a[href]").each { |link| link["rel"] = LINK_REL }
    fragment.to_html.html_safe
  end
end
