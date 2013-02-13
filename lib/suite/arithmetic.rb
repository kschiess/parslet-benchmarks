
require 'benchmark'

require 'parslet/export'
require 'treetop'
require 'csv'
require 'rsec'

class Suite::Arithmetic
  def self.variants
    %w(parslet treetop rsec )
  end
  def self.range
    1000..20000
  end

  class Parslet < Parslet::Parser
    root :expression

    rule(:expression) { term >> (match['+-/*'] >> term).repeat(1) | term }
    rule(:term) { factor }
    rule(:factor) { str('(') >> expression >> str(')') | number }
    rule(:number) { match['0-9'].repeat(1) }
  end
  class Rsec
    include ::Rsec::Helpers

    attr_reader :arithmetic

    def initialize 
      # build the parser
      num    = prim(:double).fail 'number'
      paren  = '('.r >> lazy{expr} << ')'
      factor = num | paren
      term   = factor.join(one_of_('*/%').fail 'operator')
      expr   = term.join(one_of_('+-').fail 'operator')
      @arithmetic = expr.eof
    end

    def parse input
      @arithmetic.parse input
    end
  end

  def initialize n
    @n = n
    @parsers = {
      parslet: Parslet.new,
      rsec: Rsec.new, 
      treetop: Treetop.load_from_string(fix(Parslet.new.to_treetop)).new
    }
  end

  def run variants
    result = {}
    input = generate_input @n
    # puts input

    variants.each do |v|
      benchmark = Benchmark.measure { run_variant(v, input) }

      result[v] = benchmark.utime
    end

    return input.size, result
  end

  def run_variant variant, input
    @parsers[variant.to_sym].parse(input)
  end

  def generate_input n
    s = rand(1000).to_s
    while s.size < n
      s += rand_operator + "#{rand(1000)}"
    end
    s
  end
  def rand_operator
    "+-/*"[rand(4)]
  end

  def fix(str)
    str.gsub('Suite::Arithmetic::Parslet', 'TreetopGrammar')
  end
end