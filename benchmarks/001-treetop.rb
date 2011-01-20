$:.unshift File.dirname(__FILE__) + "/../lib"
require 'parslet'
include Parslet

# Do a simple kind of benchmark using the built in Treetop parser. This 
# gives the parser code a good workout without being too complex to write. 

# time ruby benchmark/001.rb on my MacBook Air, user time
# 14Jan2010       0m0.960s

100.times do
  exp(%Q(
    ('a'* / 'b'* / 'c'*)?
  ).strip)
end
