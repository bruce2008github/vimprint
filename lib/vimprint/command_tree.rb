module Vimprint

  module ModeOpener
    def add_to(list, modestack)
      list << self
      modestack << self
    end
  end

  module ModalCommand
    def add_to(list, modestack)
      list << self
    end
  end

  module ModeCloser
    def add_to(list, modestack)
      list << self
      modestack.pop
    end
  end

  class CommandTree
    attr_reader :root, :stack

    def initialize(root=[])
      @root = root
      @stack = [@root]
    end

    def entry_point
      @stack.last
    end

    def << (item)
      if item.respond_to?(:add_to)
        item.add_to(self.entry_point, self.stack)
      else
        entry_point << item
      end
    end

    def push_mode(mode=[])
      entry_point.push(mode)
      @stack.push(mode)
    end

    def pop_mode()
      @stack.pop
    end

  end
end
