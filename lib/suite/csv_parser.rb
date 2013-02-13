
require 'benchmark'

require 'parslet/export'
require 'treetop'
require 'csv'

class Suite::CsvParser
  def self.name
    "csv"
  end
  def self.variants
    %w(parslet treetop csv)
  end
  def self.range
    200..20_000
  end
  
  def initialize(n)
    @n = n
    @grammar = Grammar.new
    @treetop = Treetop.load_from_string(fix(@grammar.to_treetop)).new
  end
  
  def fix(str)
    str.gsub('Suite::CsvParser::Grammar', 'SuiteCsvParserGrammar')
  end
  
  # Returns effective input size and a hash mapping variants to CPU time used.
  #
  def run(variants)
    result = {}
    input = generate_input(@n).freeze
    
    variants.each do |variant|
      benchmark = Benchmark.measure { run_variant(variant, input) }
      
      result[variant] = benchmark.utime
    end
    
    return input.size, result
  end
  
  def generate_input(n)
    s = %Q(GPNLWG,"",PNX,994190320,5089227,"=""6996479699989""",90/00/92,6452735,95784560,6,MG929000.OCS,W0902-,09/90/96,09/90/96,-002.59) 
    s * ((n + s.size-1) / s.size) + "\n"
  end
  
  def run_variant(variant, input)
    case variant
    when "parslet"
      @grammar.parse(input)
    when 'treetop'
      res = @treetop.parse(input)
      fail unless res
    when 'csv'
      CSV.parse(input)
    end
  end
  
  # A smalltalk grammar from https://github.com/rkh/Reak (R. Konstantin Haase)
  #
  class Grammar < Parslet::Parser
    rule(:file)        {(record.as(:row) >> newline).repeat(1)}
    rule(:record)      {field.as(:column) >> (comma >> field.as(:column)).repeat}
    rule(:field)       {escaped | non_escaped}
    rule(:escaped)     {d_quote >> (textdata | comma | cr | lf | d_quote >> d_quote).repeat >> d_quote}
    rule(:non_escaped) {textdata.repeat}
    rule(:textdata)    {((comma | d_quote | cr | lf).absent? >> any).repeat(1)}
    rule(:newline)     {lf >> cr.maybe}
    rule(:lf)          {str("\n")}
    rule(:cr)          {str("\r")}
    rule(:d_quote)     {str('"')}
    rule(:comma)       {str(',')} 

    root(:file)
  end
end