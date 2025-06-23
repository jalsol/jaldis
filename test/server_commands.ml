open Core
open Resp
open Server
module S = Storage

let run cmd args =
  Commands.run_command cmd ~args |> Serializer.serialize |> Printf.printf "%S\n"
;;

let%expect_test "basic string & list commands" =
  S.flushdb ();

  run "SET" [ "str1"; "hello" ];
  run "GET" [ "str1" ];

  run "LLEN" [ "list1" ];

  run "LPUSH" [ "list1"; "a"; "b"; "c" ];
  run "RPUSH" [ "list1"; "x"; "y" ];
  run "LRANGE" [ "list1"; "0"; "-1" ];

  run "LLEN" [ "list1" ];
  run "LPOP" [ "list1" ];
  run "RPOP" [ "list1" ];
  run "LRANGE" [ "list1"; "0"; "1" ];

  run "LRANGE" [ "list1"; "-2"; "-1" ];

  run "LLEN" [ "list1" ];
  run "LPOP" [ "list1"; "3" ];

  run "LLEN" [ "list1" ];
  run "LRANGE" [ "list1"; "0"; "-1" ];

  [%expect
    {|
    "+OK\r\n"
    "$5\r\nhello\r\n"
    ":0\r\n"
    ":3\r\n"
    ":5\r\n"
    "*5\r\n$1\r\nc\r\n$1\r\nb\r\n$1\r\na\r\n$1\r\nx\r\n$1\r\ny\r\n"
    ":5\r\n"
    "$1\r\nc\r\n"
    "$1\r\ny\r\n"
    "*2\r\n$1\r\nb\r\n$1\r\na\r\n"
    "*2\r\n$1\r\na\r\n$1\r\nx\r\n"
    ":3\r\n"
    "*3\r\n$1\r\nb\r\n$1\r\na\r\n$1\r\nx\r\n"
    ":0\r\n"
    "*0\r\n"
    |}]
;;
