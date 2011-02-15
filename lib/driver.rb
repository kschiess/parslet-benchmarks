class Driver < Struct.new(:suite)
  def steps 
    10
  end
  
  def run(args)
    # Defaults to all variants. If variants are given on the command line, 
    # only run those that are offered by the suite.
    variants = args.empty? ? 
      suite.variants : 
      suite.variants & args
      
    start = suite.range.first
    stop  = suite.range.last
    increment = (stop - start) / steps
    
    printf " size       " + "%-10s"*variants.size + "\n", 
      *variants
    start.step(stop, increment) do |current|
      single_run(current, variants)
    end
  end
  
  def single_run(problem_size, variants)
    iteration = suite.new(problem_size)
    
    real_size, measure = iteration.run(variants)
    printf "%10d: " + "%7.3f   "*variants.size + "\n", 
      real_size, 
      *variants.map { |v| measure[v] }
  end
end