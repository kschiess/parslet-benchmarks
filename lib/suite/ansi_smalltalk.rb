
require 'benchmark'

class Suite::AnsiSmalltalk
  def self.name
    "ansi_smalltalk"
  end
  def self.variants
    %w(treetop parslet)
  end
  def self.range
    200..40_000
  end
  
  def initialize(n)
    @n = n
  end
  
  def run(variants)
    result = {}
    variants.each do |variant|
      input = generate_input(@n)
      benchmark = Benchmark.measure { run_variant(variant, input) }
      result[variant] = benchmark.utime
    end
    
    result
  end
  
  def generate_input(n)
  end
  
  def run_variant(variant, input)
  end
end