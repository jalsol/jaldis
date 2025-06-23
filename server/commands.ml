open Core
open Resp
open Rstring
open Rlist
module S = Storage

let hello =
  R.Map
    [ R.String "server", R.String "jaldis"
    ; R.String "version", R.String "0.0.1"
    ; R.String "proto", R.Int 3
    ; R.String "hotel", R.String "trivago"
    ]
;;

let ping = function
  | [] -> R.String "PONG"
  | [ msg ] -> R.Bulk_string msg
  | _ -> R.Error "ERR wrong argument"
;;

let flushdb = function
  | [] ->
    S.flushdb ();
    R.String "OK"
  | _ -> R.Error "ERR not implemented"
;;

let run_command ~args = function
  (* Protocol operations *)
  | "PING" -> ping args
  | "HELLO" -> hello
  (* String operations *)
  | "SET" -> set args
  | "GET" -> get args
  (* List operations *)
  | "LLEN" -> llen args
  | "LPUSH" -> lpush args
  | "RPUSH" -> rpush args
  | "LPOP" -> lpop args
  | "RPOP" -> rpop args
  | "LRANGE" -> lrange args
  (* Others *)
  | "FLUSHDB" -> flushdb args
  | _ -> R.Error "ERR Not implemented"
;;

let is_all_bulk_strings arr =
  List.map arr ~f:(function
    | R.Bulk_string s -> Ok s
    | _ -> Error "ERR all args have to be bulk string")
  |> Result.all
;;

let handle_msg = function
  | R.Array arr ->
    (match is_all_bulk_strings arr with
     | Error e -> R.Error e
     | Ok [] -> R.Error "ERR Empty arguments"
     | Ok (cmd :: args) -> run_command cmd ~args)
  | _ -> R.Error "ERR RESP requires an array of bulk string"
;;
