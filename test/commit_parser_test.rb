require 'test_helper'
require 'commit_parser'

class CommitParserTest < Test::Unit::TestCase
  def test_extract_without_ticket
    assert_equal({}, CommitParser.extract_items_with_actions('simple commit'))
  end

  def test_extract_with_single_ticket
    result = {38209 => {:action => :cmd_close}}
    assert_equal(result, CommitParser.extract_items_with_actions('Changes :). Fixes #38209'))
  end

  def test_extract_single_action_with_multiple_tickets
    result = {38209 => {:action => :cmd_close}, 23 => {:action => :cmd_close}}
    assert_equal result, CommitParser.extract_items_with_actions('Fixing tag form when creating items. Fixes #38209, #23')
  end

  def test_multiple_actions_and_multiple_tickets
    result = {12 => {:action => :cmd_close}, 10 => {:action => :cmd_close}, 14 => {:action => :cmd_ref}}
    assert_equal result, CommitParser.extract_items_with_actions('Changed blah and foo to do this or that. Fixes #10 and #12, and refs #14.')
  end

  def test_multiline_with_ticket
    result = {38209 => {:action => :cmd_ref}}
    assert_equal result, CommitParser.extract_items_with_actions("Cool commit\nDoing some explaining.\n References #38209")
  end

  def test_process_commit
    commit_log = Yajl::Parser.parse(fixture_file('sample_payload.json'))
    parsed_commit = CommitParser.parse_commit(commit_log['commits'][1])

    assert_equal :cmd_close, parsed_commit[60097][:action]
    assert_equal "(Chris Wanstrath, in [[de8251]](http://github.com/defunkt/github/commit/de8251ff97ee194a289832576287d6f8ad74e3d0)) update pricing a tad. Fixes #60097, refs #60095", parsed_commit[60097][:comment]

    assert_equal :cmd_ref, parsed_commit[60095][:action]
    assert_equal "(Chris Wanstrath, in [[de8251]](http://github.com/defunkt/github/commit/de8251ff97ee194a289832576287d6f8ad74e3d0)) update pricing a tad. Fixes #60097, refs #60095", parsed_commit[60095][:comment]
  end
end
