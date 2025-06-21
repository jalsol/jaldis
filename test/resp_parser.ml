open Core
open Resp
open Angstrom

let print_parse_result input =
  match parse_string ~consume:All Parser.parse input with
  | Ok ast -> print_s [%sexp (ast : Ast.t)]
  | Error msg -> print_s [%sexp (msg : string)]
;;

(* RESP Simple String *)
let%expect_test {| simple_string |} =
  print_parse_result "+hello\r\n";
  [%expect {| (String hello) |}]
;;

(* RESP Error *)
let%expect_test {| error |} =
  print_parse_result
    "-WRONGTYPE Operation against a key holding the wrong kind of value\r\n";
  [%expect
    {| (Error "WRONGTYPE Operation against a key holding the wrong kind of value") |}]
;;

(* RESP Integer *)
let%expect_test {| integer |} =
  print_parse_result ":123\r\n";
  [%expect {| (Int 123) |}]
;;

(* RESP Bulk String *)
let%expect_test {| bulk_string |} =
  print_parse_result "$6\r\nfoobar\r\n";
  [%expect {| (Bulk_string foobar) |}]
;;

(* RESP Null Bulk String *)
let%expect_test {| null_bulk_string |} =
  print_parse_result "$-1\r\n";
  [%expect {| Null |}]
;;

(* RESP Array *)
let%expect_test {| array |} =
  print_parse_result "*2\r\n+foo\r\n+bar\r\n";
  [%expect {| (Array ((String foo) (String bar))) |}]
;;

(* RESP Null Array *)
let%expect_test {| null_array |} =
  print_parse_result "*-1\r\n";
  [%expect {| Null |}]
;;

(* RESP Null (underscore) *)
let%expect_test {| null |} =
  print_parse_result "_\r\n";
  [%expect {| Null |}]
;;

(* RESP Boolean true *)
let%expect_test {| bool_true |} =
  print_parse_result "#t\r\n";
  [%expect {| (Bool true) |}]
;;

(* RESP Boolean false *)
let%expect_test {| bool_false |} =
  print_parse_result "#f\r\n";
  [%expect {| (Bool false) |}]
;;

(* RESP Double *)
let%expect_test {| double |} =
  print_parse_result ",3.1415\r\n";
  [%expect {| (Double 3.1415) |}]
;;

(* RESP Big Integer *)
let%expect_test {| big_int |} =
  print_parse_result "(123456789012345678901234567890\r\n";
  [%expect {| (Big_int 123456789012345678901234567890) |}]
;;

(* RESP Bulk Error *)
let%expect_test {| bulk_error |} =
  print_parse_result "!8\r\nERR bulk\r\n";
  [%expect {| (Bulk_error "ERR bulk") |}]
;;

(* RESP Verbatim String *)
let%expect_test {| verbatim_string |} =
  print_parse_result "=7\r\ntxt:foo\r\n";
  [%expect {| (Verbatim_string txt foo) |}]
;;

(* RESP Map *)
let%expect_test {| map |} =
  print_parse_result "%2\r\n+first\r\n:1\r\n+second\r\n:2\r\n";
  [%expect {| (Map (((String first) (Int 1)) ((String second) (Int 2)))) |}]
;;

(* RESP Attribute (backtick-prefixed in this parser) *)
let%expect_test {| attribute |} =
  print_parse_result "`2\r\n+key\r\n:123\r\n+flag\r\n#t\r\n";
  [%expect {| (Attribute (((String key) (Int 123)) ((String flag) (Bool true)))) |}]
;;

(* RESP Set *)
let%expect_test {| set |} =
  print_parse_result "~3\r\n+one\r\n+two\r\n+three\r\n";
  [%expect {| (Set ((String one) (String two) (String three))) |}]
;;

(* RESP Push *)
let%expect_test {| push |} =
  print_parse_result ">2\r\n+pubsub\r\n+message\r\n";
  [%expect {| (Push ((String pubsub) (String message))) |}]
;;
