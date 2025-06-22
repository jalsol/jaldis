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

let set = function
  | [] | [ _ ] -> R.Error "ERR not enough arguments"
  | [ R.Bulk_string key; R.Bulk_string value ] ->
    Storage.set ~key ~value;
    R.String "OK"
  | _ -> R.Error "ERR not implemented"
;;

let get = function
  | [] -> R.Error "ERR not enough arguments"
  | [ R.Bulk_string key ] ->
    let data = Storage.get ~key in
    (match data with
     | None -> R.Null
     | Some (Storage.String value) -> R.Bulk_string value
     | Some _ -> R.Error "ERR GET expects to get a string")
  | _ -> R.Error "ERR not implemented"
;;

let run_command cmd args =
  match cmd with
  | R.Bulk_string "PING" -> ping args
  | R.Bulk_string "HELLO" -> hello
  | R.Bulk_string "SET" -> set args
  | R.Bulk_string "GET" -> get args
  | _ -> R.Error "ERR Not implemented"
;;

let handle_msg = function
  | R.Array args ->
    (match args with
     | [] -> R.Error "ERR Empty arguments"
     | cmd :: rest -> run_command cmd rest)
  | _ -> R.Error "ERR RESP requires an array of bulk string"
;;
