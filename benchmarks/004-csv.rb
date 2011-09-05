# As seen in https://gist.github.com/1192215

require 'parslet'

# --------------------------------------------------
# Auxiliary code

class String
  def unquote
    self.gsub(/(^"|"$)/,"").gsub(/""/,'"')
  end
end

# --------------------------------------------------
# CSV parser

module CSV; end
class CSV::Parser < Parslet::Parser

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

class CSV::Transformer < Parslet::Transform

  rule(:column => subtree(:field)) do
    if field.is_a?(Array) # = empty array []
      nil
    else 
      field.to_s.unquote
    end
  end

  rule(:row => subtree(:array)) {array}
end

data = File.read(
  File.join(File.dirname(__FILE__), '004-test_data.csv'))
tree = CSV::Parser.new.parse(data)
CSV::Transformer.new.apply(tree)