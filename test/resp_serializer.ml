open Core
open Resp

let print_serialization resp =
  let s = Serializer.serialize resp in
  Printf.printf "%S\n" s
;;

(* RESP Simple String *)
let%expect_test {| simple_string |} =
  print_serialization (R.String "hello");
  [%expect {| "+hello\r\n" |}]
;;

(* RESP Error *)
let%expect_test {| error |} =
  print_serialization
    (R.Error "WRONGTYPE Operation against a key holding the wrong kind of value");
  [%expect {| "-WRONGTYPE Operation against a key holding the wrong kind of value\r\n" |}]
;;

(* RESP Integer *)
let%expect_test {| integer |} =
  print_serialization (R.Int 123);
  [%expect {| ":123\r\n" |}]
;;

(* RESP Bulk String *)
let%expect_test {| bulk_string |} =
  print_serialization (R.Bulk_string "foobar");
  [%expect {| "$6\r\nfoobar\r\n" |}]
;;

(* RESP Null *)
let%expect_test {| null |} =
  print_serialization R.Null;
  [%expect {| "_\r\n" |}]
;;

(* RESP Boolean true *)
let%expect_test {| bool_true |} =
  print_serialization (R.Bool true);
  [%expect {| "#t\r\n" |}]
;;

(* RESP Boolean false *)
let%expect_test {| bool_false |} =
  print_serialization (R.Bool false);
  [%expect {| "#f\r\n" |}]
;;

(* RESP Double *)
let%expect_test {| double |} =
  print_serialization (R.Double 3.1415);
  [%expect {| ",3.1415\r\n" |}]
;;

(* RESP Big Integer *)
let%expect_test {| big_int |} =
  print_serialization (R.Big_int (Z.of_string "123456789012345678901234567890"));
  [%expect {| "(123456789012345678901234567890\r\n" |}]
;;

(* RESP Bulk Error *)
let%expect_test {| bulk_error |} =
  print_serialization (R.Bulk_error "ERR bulk");
  [%expect {| "!8\r\nERR bulk\r\n" |}]
;;

(* RESP Verbatim String *)
let%expect_test {| verbatim_string |} =
  print_serialization (R.Verbatim_string ("txt", "foo"));
  [%expect {| "=7\r\ntxt:foo\r\n" |}]
;;

(* RESP Array *)
let%expect_test {| array |} =
  print_serialization (R.Array [ R.String "foo"; R.String "bar" ]);
  [%expect {| "*2\r\n+foo\r\n+bar\r\n" |}]
;;

(* RESP Map *)
let%expect_test {| map |} =
  print_serialization (R.Map [ R.String "first", R.Int 1; R.String "second", R.Int 2 ]);
  [%expect {| "%2\r\n+first\r\n:1\r\n+second\r\n:2\r\n" |}]
;;

(* RESP Attribute *)
let%expect_test {| attribute |} =
  print_serialization
    (R.Attribute [ R.String "key", R.Int 123; R.String "flag", R.Bool true ]);
  [%expect {| "`2\r\n+key\r\n:123\r\n+flag\r\n#t\r\n" |}]
;;

(* RESP Set *)
let%expect_test {| set |} =
  print_serialization (R.Set [ R.String "one"; R.String "two"; R.String "three" ]);
  [%expect {| "~3\r\n+one\r\n+two\r\n+three\r\n" |}]
;;

(* RESP Push *)
let%expect_test {| push |} =
  print_serialization (R.Push [ R.String "pubsub"; R.String "message" ]);
  [%expect {| ">2\r\n+pubsub\r\n+message\r\n" |}]
;;
