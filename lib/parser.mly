%{
open Core
open Ast
%}

%token PLUS
%token MINUS
%token COLON
%token DOLLAR
%token ARISK
%token USCORE
%token HASH
%token COMMA
%token LPAREN
%token EXCLAM
%token EQUAL
%token PCENT
%token TILDE
%token RANGLE
%token CRLF
%token <string> VALUE
%token EOF

%start <Ast.t> msg
%%

msg:
  | elem EOF { $1 }

elem:
  | PLUS VALUE CRLF
    { String $2 }
  | MINUS VALUE CRLF
    { Error $2 }
  | COLON VALUE CRLF
    { Int (Int.of_string $2) }
  | DOLLAR VALUE CRLF VALUE CRLF
    { Bulk_string (Int.of_string $2, $4) }
  | ARISK VALUE CRLF list(terminated(elem, CRLF))
    { Array (Int.of_string $2, $4) }
  | USCORE CRLF
    { Null }
  | HASH VALUE CRLF
    { match $2 with
      | "t" -> Bool true
      | "f" -> Bool false
      | _ as s -> failwithf "Bool expect t/f, receive %s" s ()
    }
  | COMMA VALUE CRLF
    { Double (Float.of_string $2) }
  | LPAREN VALUE CRLF
    { Big_int (Z.of_string $2) }
  | EXCLAM VALUE CRLF VALUE CRLF
    { Bulk_error (Int.of_string $2, $4) }
  | EQUAL VALUE CRLF VALUE CRLF
    { match String.split $4 ~on:':' with
      | enc :: data :: [] -> Verbatim_string (Int.of_string $2, enc, data)
      | _ -> failwithf "Verbatim string expect enc:data, receive %s" $4 ()
    }
  | PCENT VALUE CRLF list(pair(terminated(elem, CRLF), terminated(elem, CRLF)))
    { Map (Int.of_string $2, $4) }
  | TILDE VALUE CRLF list(terminated(elem, CRLF))
    { Set (Int.of_string $2, $4) }
  | RANGLE VALUE CRLF list(terminated(elem, CRLF))
    { Push (Int.of_string $2, $4) }
