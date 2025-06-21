open Core
open Resp
open Angstrom

let parse_then_serialize input =
  match parse_string ~consume:All Parser.parse input with
  | Ok ast -> Serializer.serialize ast
  | Error err -> "ERR" ^ err
;;

(* Empty bulk string *)
let%expect_test {| bulk_empty |} =
  let input = "$0\r\n\r\n" in
  let round = parse_then_serialize input in
  Printf.printf "%S\n" round;
  [%expect {| "$0\r\n\r\n" |}]
;;

(* Bulk string containing CRLF inside content *)
let%expect_test {| bulk_embedded_crlf |} =
  let input = "$5\r\nfoo\r\n\r\n" in
  let round = parse_then_serialize input in
  Printf.printf "%S\n" round;
  [%expect {| "$5\r\nfoo\r\n\r\n" |}]
;;

(* Array with mixed and null elements *)
let%expect_test {| array_mixed |} =
  let input = "*4\r\n:-123\r\n$0\r\n\r\n_\r\n#f\r\n" in
  let round = parse_then_serialize input in
  Printf.printf "%S\n" round;
  [%expect {| "*4\r\n:-123\r\n$0\r\n\r\n_\r\n#f\r\n" |}]
;;

(* Nested Map *)
let%expect_test {| nested_map |} =
  let input = "%1\r\n+outer\r\n%1\r\n+inner\r\n:42\r\n" in
  let round = parse_then_serialize input in
  Printf.printf "%S\n" round;
  [%expect {| "%1\r\n+outer\r\n%1\r\n+inner\r\n:42\r\n" |}]
;;

(* Attribute with nested set *)
let%expect_test {| attribute_set |} =
  let input = "`1\r\n+flags\r\n~2\r\n+read\r\n+write\r\n" in
  let round = parse_then_serialize input in
  Printf.printf "%S\n" round;
  [%expect {| "`1\r\n+flags\r\n~2\r\n+read\r\n+write\r\n" |}]
;;

(* Negative big integer *)
let%expect_test {| big_int_neg |} =
  let input = "(-987654321987654321987654321\r\n" in
  let round = parse_then_serialize input in
  Printf.printf "%S\n" round;
  [%expect {| "(-987654321987654321987654321\r\n" |}]
;;

(* Double in scientific notation *)
let%expect_test {| double_-inf |} =
  let input = ",1e10\r\n" in
  let round = parse_then_serialize input in
  Printf.printf "%S\n" round;
  [%expect {| ",10000000000.\r\n" |}]
;;

let%expect_test {| double_nan |} =
  let input = ",nan\r\n" in
  let round = parse_then_serialize input in
  Printf.printf "%S\n" round;
  [%expect {| ",nan\r\n" |}]
;;

let%expect_test {| double_-inf |} =
  let input = ",-inf\r\n" in
  let round = parse_then_serialize input in
  Printf.printf "%S\n" round;
  [%expect {| ",-inf\r\n" |}]
;;

(* Push with bulk string containing CRLF *)
let%expect_test {| push_crlf_bulk |} =
  let input = ">2\r\n+notice\r\n$7\r\nhi\r\nall\r\n" in
  let round = parse_then_serialize input in
  Printf.printf "%S\n" round;
  [%expect {| ">2\r\n+notice\r\n$7\r\nhi\r\nall\r\n" |}]
;;

(* Empty array *)
let%expect_test {| array_empty |} =
  let input = "*0\r\n" in
  Printf.printf "%S\n" (parse_then_serialize input);
  [%expect {| "*0\r\n" |}]
;;

(* Empty map *)
let%expect_test {| map_empty |} =
  let input = "%0\r\n" in
  Printf.printf "%S\n" (parse_then_serialize input);
  [%expect {| "%0\r\n" |}]
;;

(* Empty set *)
let%expect_test {| set_empty |} =
  let input = "~0\r\n" in
  Printf.printf "%S\n" (parse_then_serialize input);
  [%expect {| "~0\r\n" |}]
;;

(* Empty attribute *)
let%expect_test {| attribute_empty |} =
  let input = "`0\r\n" in
  Printf.printf "%S\n" (parse_then_serialize input);
  [%expect {| "`0\r\n" |}]
;;

(* Bulk string with zero‑padded length field *)
let%expect_test {| bulk_zero_padded |} =
  let input = "$03\r\nabc\r\n" in
  Printf.printf "%S\n" (parse_then_serialize input);
  [%expect {| "$3\r\nabc\r\n" |}]
;;

(* Integer with explicit plus sign *)
let%expect_test {| int_plus |} =
  let input = ":+42\r\n" in
  Printf.printf "%S\n" (parse_then_serialize input);
  [%expect {| ":42\r\n" |}]
;;

(* Big integer with explicit plus sign *)
let%expect_test {| big_int_plus |} =
  let input = "(+987654321\r\n" in
  Printf.printf "%S\n" (parse_then_serialize input);
  [%expect {| "(987654321\r\n" |}]
;;

(* Double with uppercase exponent *)
let%expect_test {| double_upper_exp |} =
  let input = ",1E-5\r\n" in
  Printf.printf "%S\n" (parse_then_serialize input);
  [%expect {| ",1e-05\r\n" |}]
;;

(* Empty push frame *)
let%expect_test {| push_empty |} =
  let input = ">0\r\n" in
  Printf.printf "%S\n" (parse_then_serialize input);
  [%expect {| ">0\r\n" |}]
;;

(* Bulk string with wrong declared length *)
let%expect_test {| bulk_len_mismatch_err |} =
  let input = "$4\r\nabc\r\n" in
  Printf.printf "%S\n" (parse_then_serialize input);
  [%expect {| "ERR: no more choices" |}]
;;

(* UTF‑8 Bulk String with Japanese characters (5 chars, 15 bytes) *)
let%expect_test {| utf8_japanese |} =
  let input = "$15\r\nこんにちは\r\n" in
  let round = parse_then_serialize input in
  Printf.printf "%S\n" round;
  [%expect
    {| "$15\r\n\227\129\147\227\130\147\227\129\171\227\129\161\227\129\175\r\n" |}]
;;

(* UTF‑8 Bulk String with emoji (1 char, 4 bytes) *)
let%expect_test {| utf8_emoji |} =
  let input = "$4\r\n🙂\r\n" in
  let round = parse_then_serialize input in
  Printf.printf "%S\n" round;
  [%expect {| "$4\r\n\240\159\153\130\r\n" |}]
;;

(* Large array of 20 integers *)
let%expect_test {| array_20 |} =
  let input =
    String.concat
      ("*20\r\n" :: List.init 20 ~f:(fun i -> Printf.sprintf ":%d\r\n" (i + 1)))
  in
  let round = parse_then_serialize input in
  Printf.printf "%S\n" round;
  [%expect
    {| "*20\r\n:1\r\n:2\r\n:3\r\n:4\r\n:5\r\n:6\r\n:7\r\n:8\r\n:9\r\n:10\r\n:11\r\n:12\r\n:13\r\n:14\r\n:15\r\n:16\r\n:17\r\n:18\r\n:19\r\n:20\r\n" |}]
;;

(* Deeply nested arrays (depth 10) that end in Null *)
let%expect_test {| nested_arrays_10 |} =
  let rec make depth acc =
    if depth = 0 then acc ^ "_\r\n" else make (depth - 1) (acc ^ "*1\r\n")
  in
  let input = make 10 "" in
  let round = parse_then_serialize input in
  Printf.printf "%S\n" round;
  [%expect {| "*1\r\n*1\r\n*1\r\n*1\r\n*1\r\n*1\r\n*1\r\n*1\r\n*1\r\n*1\r\n_\r\n" |}]
;;

(* Unknown type character ^ should error *)
let%expect_test {| invalid_type |} =
  let input = "^oops\r\n" in
  let round = parse_then_serialize input in
  print_endline round;
  [%expect {| ERR: no more choices |}]
;;

(* Simple string missing CR should error *)
let%expect_test {| missing_crlf |} =
  let input = "+hello\n" in
  let round = parse_then_serialize input in
  print_endline round;
  [%expect {| ERR: no more choices |}]
;;

(* Bulk string with non‑numeric length *)
let%expect_test {| bulk_len_nonnumeric |} =
  let input = "$x\r\nhey\r\n" in
  let round = parse_then_serialize input in
  print_endline round;
  [%expect {| ERR: no more choices |}]
;;
