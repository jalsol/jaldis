open Core
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
  | [ msg ] -> R.Bulk_string msg
  | _ -> R.Error "ERR wrong argument"
;;

let set = function
  | [] | [ _ ] -> R.Error "ERR not enough arguments"
  | [ key; value ] ->
    Storage.set ~key ~value;
    R.String "OK"
  | _ -> R.Error "ERR not implemented"
;;

let get = function
  | [] -> R.Error "ERR not enough arguments"
  | [ key ] ->
    let data = Storage.get ~key in
    (match data with
     | None -> R.Null
     | Some (Storage.String value) -> R.Bulk_string value
     | Some _ -> R.Error "ERR GET expects to get a string")
  | _ -> R.Error "ERR not implemented"
;;

let run_command ~args = function
  | "PING" -> ping args
  | "HELLO" -> hello
  | "SET" -> set args
  | "GET" -> get args
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
