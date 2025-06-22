open! Core
open Resp

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
  | [ R.String msg ] -> R.Bulk_string msg
  | [ R.Bulk_string msg ] -> R.Bulk_string msg
  | _ -> R.Error "ERR wrong argument"
;;

let run_command cmd args =
  match cmd with
  | R.Bulk_string "PING" -> ping args
  | R.Bulk_string "HELLO" -> hello
  | _ -> R.Error "ERR Not implemented"
;;

let handle_msg = function
  | R.Array args ->
    (match args with
     | [] -> R.Error "ERR Empty arguments"
     | cmd :: rest -> run_command cmd rest)
  | _ -> R.Error "ERR RESP requires an array of bulk string"
;;
