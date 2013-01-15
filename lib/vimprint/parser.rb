require "parslet"

module Vimprint
  class Parser < Parslet::Parser
    rule(:escape) { match('\e').as(:escape) }
    rule(:enter) { match('\r').as(:enter) }
    rule(:count) {
      (match('[0-9]').repeat(2) | match('[1-9]')).as(:count)
    }

    # Ways of typing
    rule(:type_into_document) {
      match('[^\e]').repeat.as(:typing)
    }
    rule(:type_into_cmdline) {
      match('[^\r\e]').repeat.as(:typing)
    }

    # Simple motions
    ONE_KEY_MOTIONS = 'hHjklLMwbeWBEnNG$0^%*#;,|'
    rule(:one_key_motion) {
      match("[#{ONE_KEY_MOTIONS}]").as(:motion)
    }
    G_KEY_MOTIONS = 'geEhjklm*#0^$'
    rule(:g_key_motion) {
      (str('g') >> match("[#{G_KEY_MOTIONS}]")).as(:motion)
    }
    rule(:find_char_motion) {
      (match('[fFtT]') >> match('[^\e]') ).as(:motion)
    }
    rule(:motion) {
      count.maybe >>
      (one_key_motion | g_key_motion | find_char_motion)
    }

    # Register setters and getters (cut, copy and paste)
    rule(:register) {
      (str('"') >> match('[a-zA-Z0-9":.%#*+~_/-]')).as(:reg)
    }
    rule(:put_command) {
      count.maybe >>
      register.maybe >>
      (
        match('[g\]\[]').maybe >>
        match('[pP]')
      )
      .as(:put)
    }

    # Operators
    rule(:operator) {
      (match('[dy><=]') | str('g') >> match('[~uUq?w]'))
    }
    rule(:operation_linewise) {
      (
        operator.repeat(2,2) |
        str('g') >> match('[~uUq?w]').repeat(2,2)
      ).as(:operation_linewise)
    }
    rule(:operation_motionwise) {
      (operator.as(:operator) >> motion)
    }
    rule(:operation) {
      count.as(:op_count).maybe >>
      (operation_linewise | operation_motionwise )
    }

    # Insertion
    rule(:begin_insert) {
      count.maybe >>
      (
        match('[iIaAoOsSC]').as(:switch) |
        str('gi').as(:switch) |
        str('c').as(:operator) >> motion |
        str('cc').as(:operation_linewise)
      )
    }

    rule(:insertion) {
      begin_insert >> type_into_document >> escape.maybe
    }

    # Catch aborted 2-keystroke commands (a.k.a. 'distrokes')
    # e.g. g* and ]m commands require 2 keystrokes
    #      pressing <Esc> after g or ] aborts the command
    rule(:unfinished_distroke) {
      ( match('[gzfFtT\]\[]') ).as(:part_distroke)
    }
    rule(:aborted_distroke) {
      ( match('[gzfFtT\]\[]') >> match('[\e]') ).as(:aborted_distroke)
    }
    rule(:aborted_cmd) { aborted_distroke }

    # Ex Command
    rule(:begin_ex_cmd) { match(':').as(:prompt) }
    rule(:run_ex_cmd) {
      begin_ex_cmd >> type_into_cmdline >> enter
    }
    rule(:abort_ex_cmd) {
      begin_ex_cmd >> type_into_cmdline >> escape
    }
    rule(:part_ex_cmd) {
      begin_ex_cmd >> type_into_cmdline
    }
    rule(:ex_command) { (run_ex_cmd | abort_ex_cmd | part_ex_cmd) }

    rule(:normal) {
      (insertion | ex_command | motion | put_command | operation | aborted_cmd | unfinished_distroke).repeat
    }
    root(:normal)
  end
end
