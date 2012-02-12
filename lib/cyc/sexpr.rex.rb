#--
# DO NOT MODIFY!!!!
# This file is automatically generated by rex 1.0.2
# from lexical definition file "sexpr.rex".
#++

module Cyc
class SExpressionLexer
  require 'strscan'

  class ScanError < StandardError ; end

  attr_reader :lineno
  attr_reader :filename

  def scan_setup ; end

  def action &block
    yield
  end

  def scan_str( str )
    scan_evaluate  str
    do_parse
  end

  def load_file( filename )
    @filename = filename
    open(filename, "r") do |f|
      scan_evaluate  f.read
    end
  end

  def scan_file( filename )
    load_file  filename
    do_parse
  end

  def next_token
    @rex_tokens.shift
  end

  def scan_evaluate( str )
    scan_setup
    @rex_tokens = []
    @lineno  =  1
    ss = StringScanner.new(str)
    state = nil
    until ss.eos?
      text = ss.peek(1)
      @lineno  +=  1  if text == "\n"
      case state
      when nil
        case
        when (text = ss.scan(/\#<AS:/))
           @rex_tokens.push action { [:open_as,text] }

        when (text = ss.scan(/\#</))
           @rex_tokens.push action { [:open_quote,text] }

        when (text = ss.scan(/>/))
           @rex_tokens.push action { [:close_quote,text] }

        when (text = ss.scan(/\.\.\./))
           @rex_tokens.push action { [:continuation] }

        when (text = ss.scan(/\(/))
           @rex_tokens.push action { [:open_par,text] }

        when (text = ss.scan(/\)/))
           @rex_tokens.push action { [:close_par,text] }

        when (text = ss.scan(/NIL/))
           @rex_tokens.push action { [:nil,text] }

        when (text = ss.scan(/:[^<>\r\n\"\(\):&\?\#\ ]+/))
           @rex_tokens.push action { [:cyc_symbol,text] }

        when (text = ss.scan(/\?[^<>\r\n\"\(\):&\?\#\ ]+/))
           @rex_tokens.push action { [:variable,text] }

        when (text = ss.scan(/\#\$[a-zA-Z0-9:_-]+/))
           @rex_tokens.push action { [:term,text] }

        when (text = ss.scan(/[^\r\n\"\(\):&\ ]+/))
           @rex_tokens.push action { [:atom,text] }

        when (text = ss.scan(/\"/))
           @rex_tokens.push action { state = :STRING; @str = ""; [:in_string] }

        when (text = ss.scan(/:/))
           @rex_tokens.push action { [:assertion_sep]}

        when (text = ss.scan(/[\ \t\f\r\n]/))
          ;

        when (text = ss.scan(/.|\n/))
           @rex_tokens.push action { raise "Illegal character <#{text}>" }

        else
          text = ss.string[ss.pos .. -1]
          raise  ScanError, "can not match: '" + text + "'"
        end  # if

      when :STRING
        case
        when (text = ss.scan(/[^\n\r\"\\]+/))
           @rex_tokens.push action { @str << text; [:in_string]}

        when (text = ss.scan(/\t/))
           @rex_tokens.push action { @str << "\t"; [:in_string] }

        when (text = ss.scan(/\n/))
           @rex_tokens.push action { @str << "\n"; [:in_string] }

        when (text = ss.scan(/\r/))
           @rex_tokens.push action { @str << "\n"; [:in_string] }

        when (text = ss.scan(/\\"/))
           @rex_tokens.push action { @str << '"'; [:in_string] }

        when (text = ss.scan(/\\/))
           @rex_tokens.push action { @str << "\\"; [:in_string] }

        when (text = ss.scan(/\"/))
           @rex_tokens.push action { state = nil; [:string,@str] }

        else
          text = ss.string[ss.pos .. -1]
          raise  ScanError, "can not match: '" + text + "'"
        end  # if

      else
        raise  ScanError, "undefined state: '" + state.to_s + "'"
      end  # case state
    end  # until ss
  end  # def scan_evaluate

  def do_parse
  end
end # class
end # module
