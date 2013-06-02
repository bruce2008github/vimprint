class Formatter
  attr_reader :commands
  def initialize(commands)
    @commands = commands
  end

  def print
    commands.plain_print
  end
end

class ExplainFormatter < Formatter

  def print
    commands.explain
  end
end

class NormalMode < Array
  def explain
    map(&:explain).join("\n")
  end
  def plain_print
    map(&:plain_print).join
  end
end
class VisualMode < Array
  def explain
    map(&:explain).join("\n")
  end
end
class InsertMode < Array
  def plain_print
    map(&:plain_print).join
  end
end

class Dictionary
  SINGULAR = 0
  PLURAL   = 1

  def self.lookup(keystroke, mode=:normal, count=1)
    count ||=1
    plurality = (count == 1) ? SINGULAR : PLURAL

    {
      :normal => {
        'h' => ["move 1 character to the left"],
        'j' => ['move 1 line down', "move #{count} lines down"],
        'u' => ["undo the last change"],
      },
      :visual => {
        'u' => ["downcase the selected text"],
      }
    }[mode][keystroke][plurality]
  end
end

Motion = Struct.new(:keystroke, :count) do
  def explain
    "#{count}#{keystroke} - #{Dictionary.lookup(keystroke, :normal, count)}"
  end
  def plain_print
    "#{keystroke} "
  end
end

Switch  = Struct.new(:keystroke) do
  def plain_print
    "\n#{keystroke}{"
  end
end

Input  = Struct.new(:keystroke) do
  def plain_print
    keystroke
  end
end

Terminator = Struct.new(:keystroke) do
  def plain_print
    "}\n"
  end
end

NormalCommand = Struct.new(:keystroke) do
  def explain
    "#{keystroke} - #{Dictionary.lookup(keystroke)}"
  end
end

VisualOperation = Struct.new(:keystroke) do
  def explain
    "#{keystroke} - #{Dictionary.lookup(keystroke, :visual)}"
  end
end

# NormalMode[
#   Motion.new('j'),
#   'k',
#   'l',
#   InsertMode.new(Switch.new('i'), [
#     Input.new('h'),
#     'e',
#     'l',
#     'l',
#     'o',
#     ExpressionLineMode[
#       '4',
#       '0',
#       '+',
#       '2',
#       Terminator.new("\n"),
#     ]
#     Terminator.new("\e"),
#   ]),
#   'j',
# ]
