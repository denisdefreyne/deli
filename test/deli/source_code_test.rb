# frozen_string_literal: true

require 'test_helper'

class TestDeliSourceCode < Minitest::Test
  def test_show_span_simple
    span = Deli::Span.new('foo.txt', 6, 5)
    source_code = Deli::SourceCode.new('foo.txt', 'hello world!')

    result = source_code.show_span(span, 'planet here')

    assert_equal(
      "foo.txt:1: planet here\n  1  |  hello world!\n              ^^^^^",
      result,
    )
  end

  def test_show_span_unicode
    span = Deli::Span.new('foo.txt', 6, 5)
    source_code = Deli::SourceCode.new('foo.txt', 'hëllo wörld!')

    result = source_code.show_span(span, 'planet here')

    assert_equal(
      "foo.txt:1: planet here\n  1  |  hëllo wörld!\n              ^^^^^",
      result,
    )
  end
end
