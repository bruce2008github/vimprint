require 'minitest/autorun'
require 'vimprint'

describe Vimprint::Parser do

  before do
    @parser = Vimprint::Parser.new
  end

  'iIaAoOsSC'.split(//).each do |char|
    it "matches text insertion initiated with #{char} switch" do
      tree = @parser.parse("#{char}Hello, World!\e").first
      tree.keys.must_equal [:switch, :typing, :escape]
      tree[:switch].must_equal char
      tree[:typing].must_equal "Hello, World!"
    end
  end

  it "matches text insertion initiated with gi switch" do
    tree = @parser.parse("giHello, World!\e").first
    tree.keys.must_equal [:switch, :typing, :escape]
    tree[:switch].must_equal "gi"
    tree[:typing].must_equal "Hello, World!"
  end

  it "matches unfinished text insertion" do
    tree = @parser.parse("IHello, World!").first
    tree.keys.must_equal [:switch, :typing]
    tree[:switch].must_equal "I"
    tree[:typing].must_equal "Hello, World!"
  end

  it "matches text insertion with control char" do
    tree = @parser.parse("IHello, World!:cq")
    insertion = tree[0]
    insertion.keys.must_equal [:switch, :typing, :escape]
    insertion[:switch].must_equal "I"
    insertion[:typing].must_equal "Hello, World!"
    ex_command = tree[1]
    ex_command.keys.must_equal [:prompt, :typing, :enter]
    ex_command[:prompt].must_equal ":"
    ex_command[:typing].must_equal "cq"
    ex_command[:enter].must_equal "\r"
  end

  it "matches text insertion with ^N control char" do
    tree = @parser.parse("A s shore:q!")
    insertion = tree[0]
    insertion.keys.must_equal [:switch , :typing, :escape]
    insertion[:switch].must_equal "A"
    insertion[:typing].must_equal " s shore"
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

  it "matches an incomplete Ex command" do
    tree = @parser.parse(":write").first
    tree.keys.must_equal [:prompt, :typing]
    tree[:prompt].must_equal ":"
    tree[:typing].must_equal "write"
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

  it "matches 0w as two motions (not w motion with 0 count)" do
    zero, word = @parser.parse("0w")
    zero.keys.must_equal [:motion]
    word.keys.must_equal [:motion]
    zero[:motion].must_equal "0"
    word[:motion].must_equal "w"
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

    it "matches unfinished #{char}-prefixed commands" do
      tree = @parser.parse("#{char}").first
      tree.keys.must_equal [:part_distroke]
      tree[:part_distroke].must_equal "#{char}"
    end
  end

  it "can handle unfinished distrokes" do
    tree = @parser.parse("g").first
    tree.keys.must_equal [:part_distroke]
    tree[:part_distroke].must_equal "g"
  end

  it "matches {operator}{motion} commands" do
    %w{d y > < = g~ gu gU gq g? gw}.each do |op|
      %w{e gj fa}.each do |mo|
        tree = @parser.parse("#{op}#{mo}").first
        tree.keys.must_equal [:operator, :motion]
        tree[:operator].must_equal op
        tree[:motion].must_equal mo
      end
    end
  end

  it "matches {operator}{operator} commands" do
    %w{d y > < = g~ gu gU gq g? gw}.each do |op|
      tree = @parser.parse("#{op}#{op}").first
      tree.keys.must_equal [:operation_linewise]
      tree[:operation_linewise].must_equal op*2
    end
  end

  it "matches g~~ commands" do
    %w{~ u U q ? w}.each do |op|
      tree = @parser.parse("g#{op}#{op}").first
      tree.keys.must_equal [:operation_linewise]
      tree[:operation_linewise].must_equal "g#{op}#{op}"
    end
  end

  it "matches the special case: gww as linewise operation" do
    # gww could be seen as either:
    #   {operator}{motion}
    #       gw       w
    # or
    #   {operator}{operator}
    #       gw       (g)w
    # Vim uses the latter interpretation (see :help gww)
    tree = @parser.parse("gww").first
    tree.keys.must_equal [:operation_linewise]
    tree[:operation_linewise].must_equal "gww"
  end

  it "matches {operator}[count]{motion}" do
    tree = @parser.parse("d3w").first
    tree.keys.must_equal [:operator, :count, :motion]
    tree[:operator].must_equal "d"
    tree[:count].must_equal "3"
    tree[:motion].must_equal "w"
  end

  it "matches [count]{operator}{motion}" do
    tree = @parser.parse("2dw").first
    tree.keys.must_equal [:op_count, :operator, :motion]
    tree[:op_count][:count].must_equal "2"
    tree[:operator].must_equal "d"
    tree[:motion].must_equal "w"
  end

  it "matches [count]{operator}[count]{motion}" do
    tree = @parser.parse("2d3w").first
    tree.keys.must_equal [:op_count, :operator, :count, :motion]
    tree[:op_count][:count].must_equal "2"
    tree[:operator].must_equal "d"
    tree[:count].must_equal "3"
    tree[:motion].must_equal "w"
  end

  it "matches c{motion}[full_insertion] commands" do
    %w{e gj fa}.each do |motion|
      tree = @parser.parse("c#{motion}hello, world\e").first
      tree.keys.must_equal [:operator, :motion, :typing, :escape]
      tree[:operator].must_equal "c"
      tree[:motion].must_equal motion
    end
  end

  it "matches c[count]{motion}[full_insertion] commands" do
    tree = @parser.parse("c3whello, world\e").first
    tree.keys.must_equal [:operator, :count, :motion, :typing, :escape]
    tree[:operator].must_equal "c"
    tree[:count].must_equal "3"
    tree[:motion].must_equal "w"
  end

  it "matches [count]c{motion}[full_insertion] commands" do
    tree = @parser.parse("3cwhello, world\e").first
    tree.keys.must_equal [:count, :operator, :motion, :typing, :escape]
    tree[:count].must_equal "3"
    tree[:operator].must_equal "c"
    tree[:motion].must_equal "w"
  end

  it "matches cc[full_insertion] commands" do
    tree = @parser.parse("cchello, world\e").first
    tree.keys.must_equal [:operation_linewise, :typing, :escape]
    tree[:operation_linewise].must_equal "cc"
  end

  it "matches c{motion}[part_insertion] commands" do
    %w{e gj fa}.each do |motion|
      tree = @parser.parse("c#{motion}hello, world").first
      tree.keys.must_equal [:operator, :motion, :typing]
      tree[:operator].must_equal "c"
      tree[:motion].must_equal motion
    end
  end

  it "matches cc[part_insertion] commands" do
    tree = @parser.parse("cchello, world").first
    tree.keys.must_equal [:operation_linewise, :typing]
    tree[:operation_linewise].must_equal "cc"
  end

  %w{p P gp gP [p [P ]p ]P}.each do |paste|
    it "matches naked paste command: #{paste}" do
      tree = @parser.parse(paste).first
      tree.keys.must_equal [:put]
    end
    it "matches paste command with count: 2#{paste}" do
      tree = @parser.parse("2#{paste}").first
      tree.keys.must_equal [:count, :put]
    end
  end
  %w{a m z A M Z 0 1 9 " : . % # * + ~ _ / -}.each do |register|
    it "matches paste command with a register: \"#{register}p" do
      tree = @parser.parse("\"#{register}p").first
      tree.keys.must_equal [:reg, :put]
    end
  end
  it 'matches [count]["x]paste' do
    tree = @parser.parse('2"ap').first
    tree.keys.must_equal [:count, :reg, :put]
  end
  it 'matches ["x][count]paste' do
    tree = @parser.parse('"a2p').first
    tree.keys.must_equal [:reg, :count, :put]
  end

end
