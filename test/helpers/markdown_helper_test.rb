# frozen_string_literal: true

require "test_helper"

class MarkdownHelperTest < ActionView::TestCase
  def render_body(markdown)
    render_markdown(Summary.new(body: markdown))
  end

  test "converts headings and lists" do
    html = render_body("# Heading\n\n- first\n- second\n")

    assert_match %r{<h1[^>]*>Heading}, html
    assert_includes html, "<li>first</li>"
    assert_includes html, "<li>second</li>"
  end

  test "keeps heading anchors" do
    html = render_body("# Heading\n")

    assert_includes html, %(id="heading")
  end

  test "keeps GFM tables" do
    html = render_body("| a | b |\n| --- | --- |\n| 1 | 2 |\n")

    assert_includes html, "<table>"
    assert_includes html, "<th>a</th>"
    assert_includes html, "<td>1</td>"
  end

  test "renders strikethrough and autolinks" do
    html = render_body("~~gone~~ https://example.com/draft\n")

    assert_includes html, "<del>gone</del>"
    assert_includes html, %(href="https://example.com/draft")
  end

  test "removes script tags" do
    html = render_body("<script>alert(1)</script>\n\ntext\n")

    assert_not_includes html, "<script"
    assert_not_includes html, "alert(1)"
  end

  test "strips raw HTML with event handlers" do
    html = render_body(%(<div onclick="steal()">click me</div>\n))

    assert_not_includes html, "onclick"
    assert_not_includes html, "steal()"
  end

  test "strips javascript URIs in links" do
    html = render_body("[click](javascript:alert(1))\n")

    assert_not_includes html, "javascript:"
  end

  test "adds rel to links" do
    html = render_body("[example](https://example.com)\n")

    assert_includes html, %(rel="nofollow noopener")
  end

  test "returns an html_safe string" do
    assert_predicate render_body("# Heading\n"), :html_safe?
  end
end
