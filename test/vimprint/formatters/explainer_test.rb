require 'minitest/autorun'
require 'minitest/pride'
require './lib/vimprint/formatters/explainer'

module Vimprint
  class ModelVimTest < MiniTest::Unit::TestCase

    def test_explain_simple_motions
      normal = NormalMode[
        Motion.new('h', 'h'),
        Motion.new('5h', 'h', 5),
        Motion.new('j', 'j'),
        Motion.new('5j', 'j', 5),
        Motion.new('k', 'k'),
        Motion.new('5k', 'k', 5),
        Motion.new('l', 'l'),
        Motion.new('5l', 'l', 5),
        Motion.new('b', 'b'),
        Motion.new('5b', 'b', 5),
        Motion.new('w', 'w'),
        Motion.new('5w', 'w', 5),
        Motion.new('e', 'e'),
        Motion.new('5e', 'e', 5),
        Motion.new('0', '0'),
      ]
      explanations = [
        "h - move left 1 character",
        "5h - move left 5 characters",
        "j - move down 1 line",
        "5j - move down 5 lines",
        "k - move up 1 line",
        "5k - move up 5 lines",
        "l - move right 1 character",
        "5l - move right 5 characters",
        "b - move to start of current/previous word",
        "5b - move to start of current/previous word 5 times",
        "w - move to start of next word",
        "5w - move to start of next word 5 times",
        "e - move to end of current/next word",
        "5e - move to end of current/next word 5 times",
        "0 - move to start of current line",
      ]
      formatter = ExplainFormatter.new(normal)
      assert_equal explanations.join("\n"), formatter.print
    end

    def test_explain_simple_switches
      normal = NormalMode[
        Switch.new('i'),
        Switch.new('i', 5),
        Switch.new('I'),
        Switch.new('I', 5),
        Switch.new('a'),
        Switch.new('a', 5),
        Switch.new('A'),
        Switch.new('A', 5),
        Switch.new('s'),
        Switch.new('s', 5),
        Switch.new('S'),
        Switch.new('S', 5),
        Switch.new('o'),
        Switch.new('o', 5),
        Switch.new('O'),
      ]
      explanations = [
        "i - insert in front of cursor",
        "5i - insert 5 times in front of cursor",
        "I - insert at start of line",
        "5I - insert 5 times at start of line",
        "a - append after the cursor",
        "5a - append 5 times after the cursor",
        "A - append at end of line",
        "5A - append 5 times at end of line",
        "s - delete current character and switch to insert mode",
        "5s - delete 5 characters and switch to insert mode",
        "S - delete current line and switch to insert mode",
        "5S - delete 5 lines and switch to insert mode",
        "o - open a new line below the current line, switch to insert mode",
        "5o - 5 times open a new line below the current line",
        "O - open a new line above the current line, switch to insert mode",
      ]
      formatter = ExplainFormatter.new(normal)
      assert_equal explanations.join("\n"), formatter.print
    end

    def test_explain_the_u_command
      normal = NormalMode[
        NormalCommand.new('u')
      ]
      formatter = ExplainFormatter.new(normal)
      assert_equal "u - undo the last change", formatter.print
    end

    def test_explain_the_visual_u_operator
      normal = NormalMode[
        VisualMode[
          VisualOperation.new('u')
        ]
      ]
      formatter = ExplainFormatter.new(normal)
      assert_equal "u - downcase the selected text", formatter.print
    end

    def test_explain_an_aborted_command
      normal = NormalMode[
        AbortedCommand.new("2\e")
      ]
      formatter = ExplainFormatter.new(normal)
      assert_equal "2\e - [aborted command]", formatter.print
    end

  end
end
