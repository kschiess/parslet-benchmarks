# This benchmark uses an HTTP parser that is stolen from 
# https://github.com/postmodern/net-http-server 

require 'parslet'

#
# Inspired by:
#
# * [Thin](https://github.com/macournoyer/thin/blob/master/ext/thin_parser/common.rl)
# * [Unicorn](https://github.com/defunkt/unicorn/blob/master/ext/unicorn_http/unicorn_http_common.rl)
# * [RFC 2616](http://www.w3.org/Protocols/rfc2616/rfc2616.html)
#
class RequestParser < Parslet::Parser
  #
  # Character Classes
  #
  rule(:digit) { match('[0-9]') }
  rule(:digits) { digit.repeat(1) }
  rule(:xdigit) { digit | match('[a-fA-F]') }
  rule(:upper) { match('[A-Z]') }
  rule(:lower) { match('[a-z]') }
  rule(:alpha) { upper | lower }
  rule(:alnum) { alpha | digit }
  rule(:cntrl) { match('[\x00-\x1f]') }
  rule(:ascii) { match('[\x00-\x7f]') }

  rule(:sp) { str(' ') }
  rule(:lws) { sp | str("\t") }
  rule(:crlf) { str("\r\n") | str("\n") }

  rule(:ctl) { cntrl | str("\x7f") }
  rule(:text) { lws | (ctl.absnt? >> ascii) }
  rule(:safe) { str('$') | str('-') | str('_') | str('.') }
  rule(:extra) {
    str('!') | str('*') | str("'") | str('(') | str(')') | str(',')
  }
  rule(:reserved) {
    str(';') | str('/') | str('?') | str(':') | str('@') | str('&') |
    str('=') | str('+')
  }
  rule(:sorta_safe) { str('"') | str('<') | str('>') }
  rule(:unsafe) { ctl | sp | str('#') | str('%') | sorta_safe }
  rule(:national) {
    (alpha | digit | reserved | extra | safe | unsafe).absnt? >> any
  }

  rule(:unreserved) { alpha | digit | safe | extra | national }
  rule(:escape) { str("%u").maybe >> xdigit >> xdigit }
  rule(:uchar) { unreserved | escape | sorta_safe }
  rule(:pchar) {
    uchar | str(':') | str('@') | str('&') | str('=') | str('+')
  }
  rule(:separators) {
    str('(') | str(')') | str('<') | str('>') | str('@') | str(',') |
    str(';') | str(':') | str("\\") | str('"') | str('/') | str('[') |
    str(']') | str('?') | str('=') | str('{') | str('}') | sp |
    str("\t")
  }

  #
  # Elements
  #
  rule(:token) { (ctl | separators).absnt? >> ascii }

  rule(:comment_text) { (str('(') | str(')')).absnt? >> text }
  rule(:comment) { str('(') >> comment_text.repeat >> str(')') }

  rule(:quoted_pair) { str("\\") >> ascii }
  rule(:quoted_text) { quoted_pair | str('"').absnt? >> text }
  rule(:quoted_string) { str('"') >> quoted_text >> str('"') }

  #
  # URI Elements
  #
  rule(:scheme) {
    (alpha | digit | str('+') | str('-') | str('.')).repeat
  }
  rule(:host_name) {
    (alnum | str('-') | str('_') | str('.')).repeat(1)
  }
  rule(:user_info) {
    (
      unreserved | escape | str(';') | str(':') | str('&') | str('=') |
      str('+')
    ).repeat(1)
  }

  rule(:all_paths) { str('*').as(:all) }
  rule(:path) { pchar.repeat(1) >> (str('/') >> pchar.repeat).repeat }
  rule(:query_string) { (uchar | reserved).repeat }
  rule(:param) { (pchar | str('/')).repeat }
  rule(:params) { param >> (str(';') >> param).repeat }
  rule(:frag) { (uchar | reserved).repeat }

  rule(:relative_path) {
    path.maybe.as(:path) >>
    (str(';') >> params.as(:params)).maybe >>
    (str('?') >> query_string.as(:query)).maybe >>
    (str('#') >> frag.as(:fragment)).maybe
  }
  rule(:absolute_path) { str('/').repeat(1) >> relative_path }

  rule(:absolute_uri) {
    scheme.as(:scheme) >> str(':') >> str('//').maybe >>
    (user_info.as(:user_info) >> str('@')).maybe >>
    host_name.as(:host) >>
    (str(':') >> digits.as(:port)).maybe >>
    absolute_path
  }

  rule(:request_uri) { all_paths.as(:path) | absolute_uri | absolute_path }

  #
  # HTTP Elements
  #
  rule(:request_method) { upper.repeat(1,20) | token.repeat(1) }

  rule(:version_number) { digits >> str('.') >> digits }
  rule(:http_version) { str('HTTP/') >> version_number.as(:version) }
  rule(:request_line) {
    request_method.as(:method) >>
    sp >> request_uri.as(:uri) >>
    sp >> http_version
  }

  rule(:header_name) { (str(':').absnt? >> token).repeat(1) }
  rule(:header_value) {
    (text | token | separators | quoted_string).repeat(1)
  }

  rule(:header) {
    header_name.as(:name) >> str(':') >> lws.repeat(1) >>
    header_value.as(:value) >> crlf
  }
  rule(:request) {
    request_line >> crlf >>
    header.repeat.as(:headers) >> crlf
  }

  root :request
end

10.times do
  RequestParser.new.parse(<<-REQUEST)
GET /search?q=test&hl=en&fp=1&cad=b&tch=1&ech=1&psi=DBQ4Te_qCI2Y_QaIuPSTCA12955207804903 HTTP/1.1
Host: www.google.com
Referer: http://www.google.com/
Accept: */*
User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_6; en-US) AppleWebKit/534.10 (KHTML, like Gecko) Chrome/8.0.552.237 Safari/534.10
Accept-Encoding: gzip,deflate,sdch
Avail-Dictionary: GeNLY2f-
Accept-Language: en-US,en;q=0.8
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.3
Cookie: NID=43=bgvZmm1C00aC41wQA0Yl5lVPEJZerwnK9LYDFo4Ph9_qBZFfbwT-auI64LZzdquh8StFriEuQfhrIgf_GlVd9erjOGppXZISHpoFgdiUUfpTqUbKC8gbfNh09eZXmcK7; PREF=ID=c28d27fb5ff1280b:U=fedcd44ca2fdef4f:FF=0:LD=en:CR=2:TM=1295517030:LM=1295517030:S=D36Ccqf-FQ78ZWE7

  REQUEST
end