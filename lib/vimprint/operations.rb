module Vimprint
  module Operations
    class Base
      def initialize(dict)
        dict.each {|key, value| send("#{key}=", value) }
      end

      def self.to_proc
        lambda {|dict| self.new dict }
      end
    end

    class Insertion < Base
      attr_accessor :switch, :text
      attr_writer :escape

      def to_s
        '%s{%s}' % [ switch, text ]
      end

      def to_html
      end
    end

    class ExCommand < Base
      attr_accessor :prompt, :text
      attr_writer :enter

      def to_s
        '%s%s' % [ prompt, text ]
      end

      def to_html
      end
    end
  end
end
