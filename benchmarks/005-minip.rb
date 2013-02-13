$:.unshift File.dirname(__FILE__) + "/../lib"
require 'parslet'

input = 'puts(3 + 2 + 61235 + 24 + 51, 252 + 235 + 23532 + 11, 2, 3, 5, 7, 11,
19)'

class MiniP < Parslet::Parser
  # Single character rules
  rule(:lparen)     { str('(') >> space? }
  rule(:rparen)     { str(')') >> space? }
  rule(:comma)      { str(',') >> space? }

  rule(:space)      { match('\s').repeat(1) }
  rule(:space?)     { space.maybe }

  # Things
  rule(:integer)    { match('[0-9]').repeat(1).as(:int) >> space? }
  rule(:identifier) { match['a-z'].repeat(1) }
  rule(:operator)   { match('[+]') >> space? }
  
  # Grammar parts
  rule(:sum)        { 
    integer.as(:left) >> operator.as(:op) >> expression.as(:right) }
  rule(:arglist)    { expression >> (comma >> expression).repeat }
  rule(:funcall)    { 
    identifier.as(:funcall) >> lparen >> arglist.as(:arglist) >> rparen }
  
  rule(:expression) { funcall | sum | integer }
  root :expression
end

parser = MiniP.new
1000.times do
  parser.parse(input)
end

