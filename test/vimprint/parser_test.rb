require 'minitest/autorun'
require 'vimprint'

describe Vimprint::Parser do

  before do
    @parser = Vimprint::Parser.new
  end

  it "matches text insertion" do
    tree = @parser.parse("IHello, World!\e").first
    tree.keys.must_equal [:switch, :typing, :escape]
    tree[:switch].must_equal "I"
    tree[:typing].must_equal "Hello, World!"
  end

  it "matches insertion of nothing" do
    tree = @parser.parse("i\e").first
    tree.keys.must_equal [:switch, :typing, :escape]
    tree[:switch].must_equal "i"
    tree[:typing].must_equal []
  end

  it "matches an Ex command" do
    tree = @parser.parse(":write\r").first
    tree.keys.must_equal [:prompt, :typing, :enter]
    tree[:prompt].must_equal ":"
    tree[:typing].must_equal "write"
  end

  it "matches an aborted Ex command" do
    tree = @parser.parse(":write\e").first
    tree.keys.must_equal [:prompt, :typing, :escape]
    tree[:prompt].must_equal ":"
    tree[:typing].must_equal "write"
  end

  it "matches an empty aborted Ex command" do
    tree = @parser.parse(":\e").first
    tree.keys.must_equal [:prompt, :typing, :escape]
    tree[:prompt].must_equal ":"
    tree[:typing].must_equal []
  end

  it "matches simple motions" do
    Vimprint::Parser::ONE_KEY_MOTIONS.split(//).each do |char|
      tree = @parser.parse(char).first
      tree.keys.must_equal [:motion]
      tree[:motion].must_equal char
    end
  end

  it "matches g-prefixed motions" do
    Vimprint::Parser::G_KEY_MOTIONS.split(//).each do |char|
      tree = @parser.parse("g#{char}").first
      tree.keys.must_equal [:motion]
      tree[:motion].must_equal "g#{char}"
    end
  end

  it "matches f{char} motions" do
    %w{f F t T}.each do |initial|
      %w{a 1 .}.each do |target|
        tree = @parser.parse(initial + target).first
        tree.keys.must_equal [:motion]
        tree[:motion].must_equal initial + target
      end
    end
  end

  it "matches motions with a count" do
    [5, 42].each do |num|
      %w{w gj fa}.each do |motion|
        tree = @parser.parse("#{num}#{motion}").first
        tree.keys.must_equal [:count, :motion]
        tree[:count].must_equal num.to_s
        tree[:motion].must_equal motion
      end
    end
  end

  %w{g z [ ] f F t T}.each do |char|
    it "matches aborted #{char}-prefixed commands" do
      tree = @parser.parse("#{char}\e").first
      tree.keys.must_equal [:aborted_distroke]
      tree[:aborted_distroke].must_equal "#{char}\e"
    end
  end

end
