module Vimprint

  module ReceivesCount
    def plurality
      return 'singular' if @count.nil?
      @count > 1 ? 'plural' : 'singular'
    end
  end

  class BaseCommand
    attr_reader :trigger, :count, :raw_keystrokes, :register, :mark

    def initialize(config={})
      @trigger        = config[:trigger]
      @count          = config[:count]
      @register       = config[:register]
      @motion         = config[:motion]
      @mark           = config[:mark]
      @operator       = config[:operator]
      @raw_keystrokes = config[:raw_keystrokes]
      @printable_char = config[:printable_char]
    end

    def ==(other)
      @trigger == other.trigger &&
      @count == other.count &&
      @raw_keystrokes == other.raw_keystrokes
    end

    def signature
      {}
    end

  end

  class NormalCommand < BaseCommand
    include ReceivesCount
    def signature
      super.merge({
        number: plurality,
        trigger: trigger
      })
    end
  end

  class RegisterCommand < NormalCommand
    def signature
      super.merge({register: register_description})
    end

    def register_description
      return 'default' if (@register.nil? || @register.empty?)
      "named"
    end
  end

  class MarkCommand < BaseCommand
    def signature
      super.merge({
        mark: mark_description,
        trigger: trigger
      })
    end

    def mark_description
      /[[:upper:]]/.match(@mark) ? "uppercase" : "lowercase"
    end
  end

  class ReplaceCommand < NormalCommand
    attr_accessor :printable_char
    def signature
      super.merge({printable_char: true})
    end
  end

  class AbortedCommand < BaseCommand
    def signature
      { aborted: true }
    end
  end

  class Motion < BaseCommand
    include ReceivesCount
    attr_accessor :motion
    def signature
      super.merge({
        number: plurality,
        motion: motion
      })
    end
  end

  class Operation < BaseCommand
    attr_accessor :operator, :motion

    def initialize(config={})
      @count          = config[:count]
      @register       = config[:register]
      @motion         = Motion.new({motion: config[:motion]})
      @operator       = config[:operator]
      @raw_keystrokes = config[:raw_keystrokes]
    end

    def signature
      {
        operator: operator,
        motion: motion.motion
      }
    end
  end

end
