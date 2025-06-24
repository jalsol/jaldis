open Core
open Resp
open Rstring
open Rlist
open Rset
open Rops
module S = Storage

let run_command ~args = function
  (* Protocol operations *)
  | "PING" -> ping args
  | "HELLO" -> hello
  | "DEL" -> del args
  | "KEYS" -> keys ()
  | "EXPIRE" -> expire args
  | "TTL" -> ttl args
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
  (* Set operations *)
  | "SADD" -> sadd args
  | "SCARD" -> scard args
  | "SMEMBERS" -> smembers args
  | "SREM" -> srem args
  | "SINTER" -> sinter args
  | "SISMEMBER" -> sismember args
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
