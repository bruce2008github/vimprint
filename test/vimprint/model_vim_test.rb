require 'minitest/autorun'
require 'minitest/pride'
require './lib/vimprint/model_vim'

module Vimprint
  class ModelVimTest < MiniTest::Unit::TestCase

    describe Stage do


      def test_stage_accumulates_raw_keystrokes
        stage = Stage.new
        stage.add_count     3
        stage.add_register 'a'
        stage.add_count     4
        stage.add_trigger  'x'
        assert_equal '3"a4x', stage.raw_keystrokes
      end

      def test_register_is_overwritten
        # Example:
        #   given buffer contents: 123456789
        #   execute this command:  3"a2"bx
        # result:
        #   both counts are multiplied, (3*2=) 6
        #   register b is set to: 123456
        #   register a is unchanged
        stage = Stage.new
        stage.add_count     3
        stage.add_register 'a'
        stage.add_count     2
        stage.add_register 'b'
        stage.add_trigger  'x'
        assert_equal "b", stage.register
      end

    end

  end
end
