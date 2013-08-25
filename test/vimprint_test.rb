require 'minitest/autorun'
require 'vimprint'

module Vimprint

  describe Vimprint do

    it 'explains consecutive commands: \'x2x"ax"zx2"ax"a2x\'' do
      assert_equal [
        ['x', 'cut 1 character into default register'],
        ['2x', 'cut 2 characters into default register'],
        ['"ax', 'cut 1 character into register a'],
        ['"zx', 'cut 1 character into register z'],
        ['2"ax', 'cut 2 characters into register a'],
        ['"a2x', 'cut 2 characters into register a'],
        ['3"a2x', 'cut 6 characters into register a'],
      ], Vimprint.explain('x2x"ax"zx2"ax"a2x3"a2x')
    end

    it 'explains both x and X commands: \'xX\'' do
      assert_equal [
        ['x', 'cut 1 character into default register'],
        ['X', 'backspace cut 1 character into default register'],
      ], Vimprint.explain('xX')
    end

  end

end
