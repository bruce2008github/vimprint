require 'minitest/autorun'
require 'vimprint'

module Vimprint

  describe Vimprint do

    it 'explains the "x" command' do
      assert_equal [["x", "cut 1 character into default register"]], Vimprint.explain("x")
    end

  end

end
