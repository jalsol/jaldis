open! Core
open Resp

let hello =
  Ast.Map
    [ Ast.String "server", Ast.String "jaldis"
    ; Ast.String "version", Ast.String "0.0.1"
    ; Ast.String "proto", Ast.Int 3
    ; Ast.String "hotel", Ast.String "trivago"
    ]
;;

let ping = function
  | [] -> Ast.String "PONG"
  | [ Ast.String msg ] -> Ast.Bulk_string msg
  | [ Ast.Bulk_string msg ] -> Ast.Bulk_string msg
  | _ -> Ast.Error "ERR wrong argument"
;;

let run_command cmd args =
  match cmd with
  | Ast.Bulk_string "PING" -> ping args
  | Ast.Bulk_string "HELLO" -> hello
  | _ -> Ast.Error "ERR Not implemented"
;;

let handle_msg = function
  | Ast.Array args ->
    (match args with
     | [] -> Ast.Error "ERR Empty arguments"
     | cmd :: rest -> run_command cmd rest)
  | _ -> Ast.Error "ERR RESP requires an array of bulk string"
;;
