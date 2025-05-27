{
  open Parser
}

rule tokenize = parse
| '+'       { PLUS }
| '-'       { MINUS }
| ':'       { COLON }
| '$'       { DOLLAR }
| '*'       { ARISK }
| '_'       { USCORE }
| '#'       { HASH }
| ','       { COMMA }
| '('       { LPAREN }
| '!'       { EXCLAM }
| '='       { EQUAL }
| '%'       { PCENT }
| '~'       { TILDE }
| '>'       { RANGLE }
| "\r\n"    { CRLF }
| _+ as txt { VALUE txt }
| eof       { EOF }

